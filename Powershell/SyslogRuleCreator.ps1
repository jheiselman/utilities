##############################################################################
#
# File: SyslogRuleCreator.ps1
#
# Author: Jerry Heiselman (u055558)
# Date: 2015-12-7
#
##############################################################################
Set-StrictMode -Version Latest

[System.Windows.RoutedEventHandler]$browseTarget = {
    switch($this.Name) {
        "findReleaseSource" {
            $openDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $outputControl = $rulesSource
            $defaultDirectory = $null
            $dialogProperty = "SelectedPath"
            break
        }
        "findOutputDir" {
            $openDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $openDialog.SelectedPath = $outputDir.Text
            $outputControl = $outputDir
            $dialogProperty = "SelectedPath"
            break;
        }
        default {
            $openDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openDialog.InitialDirectory = $outputDir.Text
            $outputControl = $inputSource
            $dialogProperty = "FileName"
            break
        }
    }

    $result = $openDialog.ShowDialog()

    switch($result) {
        "OK" { $outputControl.Text = ($openDialog | Select -ExpandProperty $dialogProperty); break }
        default: { }
    }
}

[System.Windows.RoutedEventHandler]$generate = {
    $release = Get-Item -Path $rulesSource.Text
    $source_path = $release.FullName + "\include-syslog\cisco-ios"
    $source = Get-Item -Path $source_path

    $events = $null
    $events = New-Object System.Collections.Hashtable
    $num_headers = 0

    $data = Import-Csv -Delimiter "`t" -Path $inputSource.Text -Header "Header","Description"
    foreach ($entry in $data) {
        $parts = $entry.Header.Split('-')
        $Facility = $parts[0]

        if ($events.ContainsKey($Facility)) {
            $events[$Facility].Add($entry.Header, $entry.Description)
        } else {
            $event = New-Object System.Collections.Hashtable
            $event.Add($entry.Header, $entry.Description)
            $events.Add($Facility, $event)
        }
        $num_headers++
    }

    $messagesOutput.Text += "%c facilities found in input file%n".Replace("%c", $events.Count).Replace("%n", [System.Environment]::NewLine)
    $messagesOutput.Text += "%c headers found in input file%n".Replace("%c", $num_headers).Replace("%n", [System.Environment]::NewLine)

    foreach ($Facility in $events.Keys) {
        $output_file_name = "cisco-ios-{}.include.syslog.rules".Replace("{}", $Facility)
        $output_path = $outputDir.Text + "\" + $output_file_name

        # Check to see if we already have a rules file for this facility and if so work from it
        $messagesOutput.Text += ("Checking for existing rules file $output_file_name"+[System.Environment]::NewLine)
        $source_file = $source.GetFiles($output_file_name)
        if ($source_file) {
            $open_switches = 0
            $saw_one_switch = $false
            $contents = Get-Content -Path $source_file.FullName

            ForEach ($line in $contents) {
                if ($line -match "^\s*switch") {
                    $open_switches++
                    $saw_one_switch = $true
                }
                if ($line -match "\s*default:") {
                    $open_switches--
                }
                if ($open_switches -eq 0 -and $saw_one_switch -eq $true) {
                    break
                } else {
                    $line | Out-File -FilePath $output_path -Append
                }
            }
            $messagesOutput.Text += ("A rules file for facility $Facility already exists. Please look for '## NEW_ENTRY' and make any necessary adjustments"+[System.Environment]::NewLine)
        }
        else {
            # Write out the start of the file
            @"
case "$Facility":
    log(DEBUG, "<<<<< Entering... $output_file_name >>>>>")
    @FeedName = "$output_file_name"

    switch(`$Mnemonic) {
"@ | Out-File -FilePath $output_path
        }

        # Write the new Mnemonics to the file
        foreach ($header in $events[$Facility].Keys) {
            "$header`tUnknown`tUnknown`t3600" | Out-File -FilePath ($outputDir.Text + "\" + "new_cisco_events.lookup") -Append
            $Mnemonic = $header.Split('-')[-1]
            $description = $events[$Facility][$header]
        
            @"
        case "$Mnemonic": ## NEW_ENTRY
            # Error Message    %${header}: $description

            @AlertKey = ""


"@ | Out-File -FilePath $output_path -Append
        }

        # Write the end of the file
        @"
        default:
        
            `$UseCiscoIosDefaults = 1
    }

    log(DEBUG, "<<<< Leaving... $output_file_name >>>>")
"@ | Out-File -FilePath $output_path -Append
     }
}

Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,System.Windows.Forms
[xml]$xaml = Get-Content ($PSScriptRoot + '.\Forms\SyslogRulesCreator.xaml')
$xamlGUI = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xamlGUI.Content.Children | %{Set-Variable -Name ($_.Name) -Value $_}
$findReleaseSource.AddHandler([System.Windows.Controls.Button]::ClickEvent, $browseTarget)
$findInputFile.AddHandler([System.Windows.Controls.Button]::ClickEvent, $browseTarget)
$findOutputDir.AddHandler([System.Windows.Controls.Button]::ClickEvent, $browseTarget)
$btnGenerate.AddHandler([System.Windows.Controls.Button]::ClickEvent, $generate)
$outputDir.Text = "$HOME\Desktop"
$xamlGUI.ShowDialog() | Out-Null
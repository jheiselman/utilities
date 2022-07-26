##############################################################################
#
# File: SyslogSender.ps1
#
# Author: Jerry Heiselman (u055558)
# Date: 2015-07-15
#
##############################################################################
Set-StrictMode -Version Latest

Import-Module Syslog

[System.Windows.RoutedEventHandler]$send_message = {
    $xamlGUI.Content.Children | Where-Object { Set-Variable -Name $_.Name -Value $_ }

    $statusLabel.Content = "Status: ..."
    try {
        $rawMessage = Send-SyslogMessage -Server $hostname.Text -UDPPort $port.Text -Severity $severity.SelectedValue.Name -Facility $facility.SelectedValue.Name -CiscoStyle $cisco.IsChecked -DellStyle $dell.IsChecked -Message $message.Text
        $statusLabel.Content = "Status: Message sent"
        $messageLabel.Content = "Message: $rawMessage"
    } catch {
        $statusLabel.Content = "Status: Error: $_"
        $messageLabel.Content = ""
    }
}

Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,System.Windows.Forms
[xml]$xaml = Get-Content ($PSScriptRoot + '.\Forms\SyslogSender.xaml')
$xamlGUI = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xamlGUI.FindName("button1").AddHandler([System.Windows.Controls.Button]::ClickEvent, $send_message) | Out-Null
$xamlGUI.ShowDialog() | Out-Null
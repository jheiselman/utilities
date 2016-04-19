##############################################################################
#
# File: GenPassword.ps1
#
# Author: Jerry Heiselman
# Date: 2016-04-18
#
##############################################################################
Set-StrictMode -Version Latest

Import-Module Password

Add-Type -AssemblyName System.Windows.Forms

[System.Windows.RoutedEventHandler]$new_password = {
    $xamlGUI.Content.Children | Where { Set-Variable -Name $_.Name -Value $_ }
    $password = New-Password
    $passwordBox.Text = $password
    $button2.IsEnabled = $true
    $status1.Content = ""
}

[System.Windows.RoutedEventHandler]$copy_to_clipboard = {
    $xamlGUI.Content.Children | Where { Set-Variable -Name $_.Name -Value $_ }
    [Windows.Forms.Clipboard]::SetText($passwordBox.Text)
    $status1.Content = "Copied!"
}

Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,System.Windows.Forms
[xml]$xaml = Get-Content ($PSScriptRoot + '.\Forms\Password.xaml')
$xamlGUI = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$button1 = $xamlGUI.FindName("button1").AddHandler([System.Windows.Controls.Button]::ClickEvent, $new_password)
$button2 = $xamlGUI.FindName("button2").AddHandler([System.Windows.Controls.Button]::ClickEvent, $copy_to_clipboard)
$xamlGUI.ShowDialog() | Out-Null 
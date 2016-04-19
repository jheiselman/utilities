$key = "{NUMLOCK}"

while ($true) {
  [Windows.Systems.Forms.SendKeys]::SendWait("{NUMLOCK}")
  [Windows.Systems.Forms.SendKeys]::SendWait("{NUMLOCK}")
  Start-Sleep -s 60
}

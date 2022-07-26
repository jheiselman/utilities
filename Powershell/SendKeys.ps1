Set-StrictMode -Version Latest

$key = "{NUMLOCK}"

while ($true) {
  [Windows.Systems.Forms.SendKeys]::SendWait($key)
  [Windows.Systems.Forms.SendKeys]::SendWait($key)
  Start-Sleep -s 60
}

try {
    Add-Type -TypeDefinition "public enum Syslog_Facility { kern, user, mail, daemon, auth, syslog, lpr, news, uucp, cron, authpriv, ftp, ntp, logaudit, logalert, clock, local0, local1, local2, local3, local4, local5, local6, local7 }"
    Add-Type -TypeDefinition "public enum Syslog_Severity { emerg, alert, crit, err, warning, notice, info, debug }"
} catch {
}

Function Send-SyslogMessage {
<#
 .SYNOPSIS
  Sends a Syslog message to a server

 .DESCRIPTION
  Sends a message to a Syslog server as defined in RFC 3164. A Syslog message contains not only raw message text,
  but also a severity level and application/system within the host that generated the message

 .PARAMETER Server
  Destination Syslog server

 .PARAMETER Message
  Message to be sent. For Cisco messages, include from the percent sign (%) to the end.

 .PARAMETER Severity
  Severity level as defined in Syslog specification, must be of ENUM type Syslog_Severity

 .PARAMETER Facility
  Facility of message as defined in Syslog specification, must be of ENUM type Syslog_Facility

 .PARAMETER Hostname
  Hostname of machine the message is about, if not specified, local hostname will be used

 .PARAMETER Timestamp
  Timestamp, must be of format, 'MMM dd HH:mm:ss", if not specified, current date and time will be used

 .PARAMETER UDPPort
  Syslog UDP port to send message to. Defaults to 514.

 .PARAMETER CiscoStyle
  Boolean value that indicates whether or not this is a Cisco message. Defaults to false.

 .PARAMETER DellStyle
  Boolean value that indicates whether or not this is a Dell message. Defaults to false.

 .PARAMETER Program
  Sets the program that Syslog reports as the subject of the message. For Cisco alerts, this gets
  set to the PID of this script process

 .INPUTS
  None

 .OUTPUTS
  None

 .LINK
  http://www.ietf.org/rfc/rfc3164.txt

 .NOTES
  In order to test the Syslog Probe, add "SYNTHETIC:<host>:" to the beginning of your Message. This is done
  automatically if you use the InputFile mechanism

 .EXAMPLE
  Send-SyslogMessage mysyslogserver "The server is down!" Emergency Mail
  Sends a syslog message to mysyslogserver saying "The server is down!"
#>

    [CMDLetBinding()]
    Param
    (
        [Parameter(mandatory=$true)][String] $Server,
        [String] $Message,
        [Syslog_Severity] $Severity = "notice",
        [Syslog_Facility] $Facility = "user",
        [String] $Hostname = $env:COMPUTERNAME,
        [String] $Timestamp = (Get-Date -Format "MMM dd HH:mm:ss"),
        [int] $UDPPort = 514,
        [bool] $CiscoStyle = $false,
        [bool] $DellStyle = $false,
        [String] $Program = "Syslog-PowerShell",
        [String] $InputFile
    )

    if (($Message -ne "" -and $Message -ne $null) -and ($InputFile -ne "" -and $InputFile -ne $null)) {
        Write-Error "You must supply only one of InputFile or Message"
        break
    }

    if (($Message -eq "" -or $Message -eq $null) -and ($InputFile -eq "" -or $InputFile -eq $null)) {
        Write-Error "You must supply either one of InputFile or Message"
        break
    }

    if ($Message -eq "" -or $Message -eq $null) {
        # We must have an InputFile
        $method = "file"
    } else {
        $method = "string"
    }

    # Evaluate the facility and severity based on the enum types
    $Facility_Number = $Facility.value__
    $Severity_Number = $Severity.value__
    Write-Verbose "Syslog Facility: $Facility_Number, Severity: $Severity_Number"

    # Calculate the priority
    $Priority = ($Facility_Number * 8) + $Severity_Number
    Write-Verbose "Priority is $Priority"

    # Assemble the full syslog formatted message
    if ($CiscoStyle -eq $true) {
        $Program = $PID
    }
    if ($DellStyle -eq $true) {
        $Program = "UTC"
    }

    # Create a UDP client and send the message
    $uc = New-Object System.Net.Sockets.UdpClient
    $uc.Connect($Server, $UDPPort)
    $udpStatus = "UDPClient connection status: {0}" -f $uc.Client.Connected
    Write-Verbose $udpStatus

    if ($uc.Client.Connected -eq $False) {
        Throw "Unable to connect to server"
    }

    if ($method -eq "string") {
        $FullSyslogMessage = "<{0}>{1} {2} {3}: {4}" -f $Priority, $Timestamp, $Hostname, $Program, $Message
        Write-Verbose $FullSyslogMessage

        # Create an ASCII byte array of the message
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($FullSyslogMessage)

        # Trim to 1024 bytes per the standard
        if ($bytes.Length -gt 1024)
        {
            $bytes = $bytes[0..1023]
        }

        # Send the message via the UDPClient
        [void]$uc.Send($bytes, $bytes.Length)
    } elseif ($method -eq "file") {

        # Open the file and send each line
        Get-Content $InputFile | ForEach-Object {
            $line = $_
            $IPAddress = $line.Substring($line.IndexOf("Node=")+5, $line.IndexOf("; Details=")-$line.IndexOf("Node=")-5)
            $Details = $line.Substring($line.IndexOf("; Details=")+10)
            $FullSyslogMessage = "<{0}>{1} {2} SYNTHETIC:{3}:{4}" -f $Priority, $Timestamp, $IPAddress, $IPAddress, $Details
            Write-Verbose $FullSyslogMessage

            # Create and ASCII byte array of the message
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($FullSyslogMessage)

            # Trim to 1024 bytes per the standard
            if ($bytes.Length -gt 1024)
            {
                $bytes = $bytes[0..1023]
            }

            # Send the message via the UDPClient
            [void]$uc.Send($bytes, $bytes.Length)
        }
    }

    $FullSyslogMessage
}

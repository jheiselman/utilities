Set-StrictMode -Version Latest

$username = ""
$api_key = ""
$serverId = ""

if ($username -eq "" -or $api_key -eq "" -or $serverId -eq "") {
    Write-Output "Please edit this script and fill in the variables at the top before using it"
    exit
}

$auth_body = @{
    auth = @{
        "RAX-KSKEY:apiKeyCredentials" = @{
            username = ""
            apiKey = ""
        }
    }
}

$auth_uri = "https://identity.api.rackspacecloud.com/v2.0/tokens"
$auth_body.auth.'RAX-KSKEY:apiKeyCredentials'.username = $username
$auth_body.auth.'RAX-KSKEY:apiKeyCredentials'.apiKey = $api_key

$authentication_response = Invoke-RestMethod -Uri $auth_uri -Method Post -Body (ConvertTo-Json $auth_body) -Headers @{"Accept"= "application/json"; "Content-Type" = "application/json"}
$tenantId = ($authentication_response.access.user.roles | Where-Object -Property name -EQ "compute:default").tenantId

$console_uri = "https://ord.servers.api.rackspacecloud.com/v2/$tenantId/servers/$serverId/action"

$console_body = @{
    "os-getVNCConsole" = @{
        type = "novnc"
    }
}

$console_response = Invoke-RestMethod -Uri $console_uri -Method Post -Headers @{"Accept" = "application/json"; "Content-Type" = "application/json"; "X-Auth-Token" = $authentication_response.access.token.id} -Body (ConvertTo-Json $console_body)
#echo $console_response.console.url
start $console_response.console.url

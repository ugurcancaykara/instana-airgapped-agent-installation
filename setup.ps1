 #! /opt/microsoft/powershell/7/pwsh
 
param(
    [Parameter(HelpMessage="Instana Agent Backend-1")]
    [string]$INSTANA_AGENT_HOST_ONE,

    [Parameter(HelpMessage="Instana Agent Backend-2")]
    [string]$INSTANA_AGENT_HOST_TWO,

    [Parameter(HelpMessage="Maven Path")]
    [string]$INSTANA_MVN_CONF_PATH,
    
    [Parameter(HelpMessage="Agent Zone")]
    [string]$AGENT_ZONE,

    [Parameter(HelpMessage="Agent Tag")]
    [string]$AGENT_TAG,

    [Parameter(Mandatory, HelpMessage="Package Path")]
    [string]$INSTANA_PACKAGE_PATH,

    [Parameter(Mandatory, HelpMessage="INSTANA_AGENT_KEY")]
    [string]$INSTANA_AGENT_KEY,


    [Parameter(Mandatory ,HelpMessage="INSTANA_DOWNLOAD_KEY")]
    [string]$INSTANA_DOWNLOAD_KEY

    
)

$INSTANA_AGENT_DIR="C:\Program Files\Instana\instana-agent"
$INSTANA_DEFAULT_MVN_PATH="C:\Program Files\Instana\instana-agent\etc\mvn-settings.xml"
$INSTANA_CONF_FILE="C:\Program Files\Instana\instana-agent\etc\instana\configuration.yaml"
$INSTANA_BACKEND_FILE="C:\Program Files\Instana\instana-agent\etc\instana\com.instana.agent.main.sender.Backend.cfg"
$INSTANA_BACKEND_ONE_PATH="C:\Program Files\Instana\instana-agent\etc\instana\com.instana.agent.main.sender.Backend-1.cfg"
$INSTANA_BACKEND_TWO_PATH="C:\Program Files\Instana\instana-agent\etc\instana\com.instana.agent.main.sender.Backend-2.cfg"
$INSTANA_AGENT_ENDPOINT=""
$INSTANA_AGENT_MODE="apm"
$INSTANA_AGENT_ENDPOINT_PORT="443"

Write-Output "INSTANA_AGENT_HOST_ONE: $INSTANA_AGENT_HOST_ONE"
Write-Output "INSTANA_AGENT_HOST_TWO: $INSTANA_AGENT_HOST_TWO"
Write-Output "INSTANA_MVN_CONF_PATH: $INSTANA_MVN_CONF_PATH"
Write-Output "AGENT_ZONE: $AGENT_ZONE"
Write-Output "AGENT_TAG: $AGENT_TAG"
Write-Output "INSTANA_PACKAGE_PATH: $INSTANA_PACKAGE_PATH"
Write-Output "INSTANA_AGENT_ENDPOINT_PORT: $INSTANA_AGENT_ENDPOINT_PORT"
Write-Output "INSTANA_AGENT_KEY: $INSTANA_AGENT_KEY"
Write-Output "INSTANA_AGENT_MODE: $INSTANA_AGENT_MODE"
Write-Output "INSTANA_DOWNLOAD_KEY: $INSTANA_DOWNLOAD_KEY"
Write-Output "INSTANA_AGENT_DIR: $INSTANA_AGENT_DIR"




& $INSTANA_PACKAGE_PATH INSTANA_AGENT_ENDPOINT=$INSTANA_AGENT_ENDPOINT INSTANA_AGENT_ENDPOINT_PORT=$INSTANA_AGENT_ENDPOINT_PORT INSTANA_AGENT_KEY=$INSTANA_AGENT_KEY INSTANA_AGENT_MODE=$INSTANA_AGENT_MODE INSTANA_DOWNLOAD_KEY=$INSTANA_DOWNLOAD_KEY /quiet


 Start-Sleep -Seconds 10;

 
  

# copy maven file
if ( $INSTANA_MVN_CONF_PATH ) 
{
    Copy-Item $INSTANA_MVN_CONF_PATH -Destination $INSTANA_DEFAULT_MVN_PATH
}


# add zone
if ( $AGENT_ZONE )
{
Add-Content $INSTANA_CONF_FILE @"
com.instana.plugin.generic.hardware: 
  enabled: true
  availability-zone: '${AGENT_ZONE}'
"@
}


# add tags
if ( $AGENT_TAG )
{
Add-Content $INSTANA_CONF_FILE @"
com.instana.plugin.host:
  tags:
    - '${AGENT_TAG}'
"@
}


# copy backend file
if ( $INSTANA_AGENT_HOST_ONE -or $INSTANA_AGENT_HOST_TWO )
{
Copy-Item $INSTANA_BACKEND_FILE -Destination "C:\Program Files\Instana\instana-agent\etc\instana\com.instana.agent.main.sender.Backend-1.cfg"
Copy-Item $INSTANA_BACKEND_FILE -Destination "C:\Program Files\Instana\instana-agent\etc\instana\com.instana.agent.main.sender.Backend-2.cfg"
Remove-Item $INSTANA_BACKEND_FILE

$INSTANA_AGENT_HOST_ONE="host=${INSTANA_AGENT_HOST_ONE}"
$INSTANA_AGENT_HOST_TWO="host=${INSTANA_AGENT_HOST_TWO}"
# replace host-1 backend-1 config
(Get-Content -Path $INSTANA_BACKEND_ONE_PATH) |
    ForEach-Object {$_ -Replace 'host=ingress-blue-saas.instana.io', $INSTANA_AGENT_HOST_ONE} |
        Set-Content -Path $INSTANA_BACKEND_ONE_PATH

# replace host-2 backend-2 config
(Get-Content -Path $INSTANA_BACKEND_TWO_PATH) |
    ForEach-Object {$_ -Replace 'host=ingress-blue-saas.instana.io', $INSTANA_AGENT_HOST_TWO} |
        Set-Content -Path $INSTANA_BACKEND_TWO_PATH
}

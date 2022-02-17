# Including other files
Import-Module -Force -Name "$PSScriptRoot\UTS.Monitoring.Security.psm1"

function Get-UTSConnectivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$Target
    )
    
    $InitialStatus = Test-Connection $Target -Count 1 -Quiet
    if ($InitialStatus -eq $True) {
        Write-Output "$(Get-Date -UFormat "%Y-%m-%d | %T") |     $Target is currently online"
    } else {
        Write-Output "$(Get-Date -UFormat "%Y-%m-%d %T") $Target is currently offline"
    }

    $CurrentStatus = $InitialStatus

    While ($True) {
        $NewStatus = Test-Connection $Target -Count 1 -Quiet
        Write-Debug "$(Get-Date -UFormat "%Y-%m-%d %T") Debug: Current status: $Target is $NewStatus"

        if ($NewStatus -eq $CurrentStatus) {
            # Do nothing as status hasn't changed
        } else {
            if ($NewStatus -eq $True) {
                Write-Output "$(Get-Date -UFormat "%Y-%m-%d %T") $Target is now online"
            } else {
                Write-Output "$(Get-Date -UFormat "%Y-%m-%d %T") $Target is now offline"
            }
        }

        $CurrentStatus = $NewStatus
        Start-Sleep -Milliseconds 250
    }
   
}
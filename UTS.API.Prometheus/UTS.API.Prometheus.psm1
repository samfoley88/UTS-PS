function New-UTSPrometheusTarget {
    <#
    .SYNOPSIS
        Creates and returns a new prometheus target
    .OUTPUTS
        Returns the target as an array ready to be included in the parent array
    .EXAMPLE
        $TargetList = New-Object System.Collections.Generic.List[Hashtable]
        $Target = New-UTSPrometheusTarget -Target "localhost" -Job "WindowsServers" -Port 9200
        $TargetList.Add($Target)
    #>
    [CmdletBinding()]
    param (
        # The target IP or hostname to gather metric from
        [Parameter(Mandatory)]
        [string]
        $Target,
        # The job to include the target in
        [Parameter(Mandatory)]
        [string]
        $Job,
        # A specific "Host" label to use for the target, defaults to the "Target" value
        [Parameter()]
        [string]
        $HostLabel = $Target,
        # A specific port to use, default is 9100
        [Parameter()]
        [string]
        $Port = "9100"
    )

    
    
    $PromTarget = @{
        targets = @("$($Target):$Port")
        labels  = @{
            "job" = $Job
            "host" = $HostLabel
        }
    }   
    
    return $PromTarget
}

function New-UTSPrometheusDiscoveryFileFromAD {
    <#
    .SYNOPSIS
        Queries the user to select machines from the domain to add and then creates a discovery file
    .OUTPUTS
        Saves a discovery file to -OutputFile. If no file is specified, the file is saved to the current directory as PrometheusDiscovery.json
    .EXAMPLE
        New-UTSPrometheusDiscoveryFileFromAD -OutputFile "C:\PromDiscovery.json" -JobName "TestJobDiscovery"
    #>
    [CmdletBinding()]
    param (
        # The output location for the discovery file, default to .\PrometheusDiscovery.json
        [Parameter()]
        [string]
        $OutputFile = "PrometheusDiscovery.json",
        # The job name to use for the discovery file, mandatory
        [Parameter(Mandatory)]
        [string]
        $JobName
    )

    Write-Verbose "Asking user to select devices to monitor"
    $ComputersToAdd = Get-ADComputer -Filter * | Out-GridView -PassThru -Title "Select devices to monitor"

    $TargetList = New-Object System.Collections.Generic.List[Hashtable]

    Write-Verbose "Adding devices to list"
    $ComputersToAdd | ForEach-Object {
        Write-Debug "Adding [$($_.DNSHostName)] to list"
        $PromTarget = New-UTSPrometheusTarget $_.DNSHostName -Job $JobName -HostLabel $_.Name
        $TargetList.Add($PromTarget)
    }

    Write-Verbose "Writing discovery file to [$OutputFile]"
    ConvertTo-Json $TargetList | Out-File -FilePath $OutputFile

}

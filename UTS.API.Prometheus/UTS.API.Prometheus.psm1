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
        New-UTSPrometheusDiscoveryFileFromAD -JobName "TestJobDiscovery"
    #>
    [CmdletBinding()]
    param (
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

    return $TargetList
}

function New-UTSPrometheusBasicDockerTargets {
    [CmdletBinding()]
    param (
        # The target IP or hostname the docker server is hosted on and to gather metrics from
        [Parameter(Mandatory)]
        [string]
        $Target,
        # A specific "Host" label to use for the target, defaults to the "Target" value
        [Parameter()]
        [string]
        $HostLabel = $Target
    )

    $TargetList = New-Object System.Collections.Generic.List[Hashtable]

    $PromTarget = @{
        targets = @("$($Target):8080")
        labels  = @{
            "job" = "cAdvisors"
            "host" = $HostLabel
        }
    }  
    
    $TargetList.Add($PromTarget)

    
    $PromTarget = @{
        targets = @("$($Target):9100")
        labels  = @{
            "job" = "LinuxBoxes"
            "host" = $HostLabel
        }
    }  
    
    $TargetList.Add($PromTarget)
    
    return $TargetList
}

function New-UTSPrometheusDiscoveryFileFromTargets {
    <#
    .SYNOPSIS
        Creates a discovery file from a list of targets based by the other Prometheus target functions
    .OUTPUTS
        Outputs discovery file to -OutputFile. If no file is specified, the file is saved to the current directory as PrometheusDiscovery.json
    .EXAMPLE
        $DockerTargets = New-UTSPrometheusBasicDockerTargets -Target "LocalLoggingHost"
        $DockerTargets2 = New-UTSPrometheusBasicDockerTargets -Target "AnotherTarget"
        $ADTargets = New-UTSPrometheusDiscoveryFileFromAD -JobName "TestJobDiscovery"
        New-UTSPrometheusDiscoveryFileFromTargets -OutputFile "C:\PromDiscovery.json" $DockerTargets $DockerTargets2 $ADTargets 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromRemainingArguments)]
        [Object]
        $Targets,
        # The output location for the discovery file, default to .\PrometheusDiscovery.json
        [Parameter()]
        [string]
        $OutputFile = "PrometheusDiscovery.json"
    )
    $FullTargetList = New-Object System.Collections.Generic.List[Hashtable]

    $Targets | ForEach-Object {
        Write-Debug "Adding [$($_ | ConvertTo-Json -Compress)] to list"
        $FullTargetList = $FullTargetList + $_
    }

    Write-Verbose "Writing discovery file to [$OutputFile]"
    ConvertTo-Json $FullTargetList | Out-File -FilePath $OutputFile

}
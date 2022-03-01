function Get-UTSAllHistory {
    Get-Content (Get-PSReadlineOption).HistorySavePath
}

function Get-UTSRandomPassword {
    param (
        [Parameter()]
        [int] $Length = 40,
        [int] $MinSpecialChars = 1,
        [switch] $SecureString = $false
    )
    Add-Type -AssemblyName 'System.Web'
    $password = [System.Web.Security.Membership]::GeneratePassword($Length, $MinSpecialChars)

    if ($SecureString) {
        Write-Information "Generated password is:"
        Write-Information $password
        $PasswordSecureString = ConvertTo-SecureString -String $password -AsPlainText -Force
        return $PasswordSecureString
    } else {
        return $password
    }

}

function Get-UTSVariablesFromJson {
<#
    .SYNOPSIS
        Converts a JSON string (single level) to individual variables.
    .OUTPUTS
        None itself, the variables are set in the script scope
    .EXAMPLE
        Get-UTSVariablesFromJson -Json $JsonString
        
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        # The JSON string to parse
        [string] $Json
    )
    
    $Json | ConvertFrom-Json | ForEach {$_.PSObject.Properties | ForEach-Object { New-Variable -Name $_.Name -Value $_.Value -Force -Scope global}}

}

function Test-UTSPrivateIP {
    <#
        .SYNOPSIS
            Use to determine if a given IP address is within the IPv4 private address space ranges.
        .DESCRIPTION
            Returns $true or $false for a given IP address string depending on whether or not is is within the private IP address ranges.
        .PARAMETER IP
            The IP address to test.
        .EXAMPLE
            Test-PrivateIP -IP 172.16.1.2
        .EXAMPLE
            '10.1.2.3' | Test-PrivateIP
    #>
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [string]
        $IP
    )

    if ($IP -Match '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)') {
        $true
    }
    else {
        $false
    }
}
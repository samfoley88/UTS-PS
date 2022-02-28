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

function Get-UTSAllHistory {
    Get-Content (Get-PSReadlineOption).HistorySavePath
}

function Get-UTSRandomPassword {
    param (
        [Parameter()]
        [int] $length = 40,
        [int] $amountOfNonAlphanumeric = 1
    )
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}

# Add documentation comment
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

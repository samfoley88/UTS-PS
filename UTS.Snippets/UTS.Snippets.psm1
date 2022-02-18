function Get-UTSAllHistory {
    Get-Content (Get-PSReadlineOption).HistorySavePath
}

function Get-RandomPassword {
    param (
        [Parameter()]
        [int] $length = 40,
        [int] $amountOfNonAlphanumeric = 1
    )
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}

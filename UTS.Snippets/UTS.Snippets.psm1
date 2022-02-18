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


$PlainPassword = Get-RandomPassword -length 40
$SecurePassword = ConvertTo-SecureString -AsPlainText -Force -String $PlainPassword
Set-LocalUser -Name LifeSaver -Password $SecurePassword -PasswordNeverExpires $True
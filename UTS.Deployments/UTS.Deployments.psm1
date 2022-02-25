function Set-UTSConfigToken() {
    [CmdletBinding()]
    param (
        [Parameter()]
        # The configuration file to be updated
        [string] $ConfigFile,
        # The token to be replaced (provided in full, ie "<token>")
        [string]$Target,
        # The new config element
        [string]$ConfigElement
    )

    ((Get-Content -path $ConfigFile -Raw) -replace $Target,$ConfigElement) | Set-Content -Path $ConfigFile
}
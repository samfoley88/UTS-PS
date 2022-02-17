# TODO:
# - Check on other machines and filter appropriately for acceptable ones etc
function Get-UTSElevatedLogins {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]
        $Age = 2
    )

    Write-Verbose "Getting elevated logins"
    Write-Debug "Fetching events from the last $Age hours from log"
    $ElevatedLogins = Get-EventLog -LogName Security -After (Get-Date).AddHours(-$Age) | Where-Object { $_.Message -match 'Elevated Token:\s*%%1842' }
    Write-Debug "Fetched elevated login events from log, found [$($ElevatedLogins.Count)] events"

    $ElevatedLoginsToReturn = New-Object System.Collections.ArrayList

    # Loop through all found logins
    $ElevatedLogins | ForEach-Object {
        
        #region Extract data from log
        # Regex to get the data we need from the event
        $RegexResults = $_.Message | Select-String -Pattern '(?sm)Logon Type:\s*([^\s]*)\s*Restricted Admin Mode:.*New Logon:.*Account Name:\s*([^\s]*)\s*Account Domain:\s*([^\s]*)\s*Logon ID:.*Source Network Address:\s*([\S]*)\s*Source Port' -AllMatches
        
        # Assign results to variables
        $RegexResults | ForEach-Object {
            $LogonType = $RegexResults.Matches.Groups[1].Value
            $AccountName = $RegexResults.Matches.Groups[2].Value
            $AccountDomain = $RegexResults.Matches.Groups[3].Value
            $LogonID = $RegexResults.Matches.Groups[4].Value
            $SourceNetworkAddress = $RegexResults.Matches.Groups[5].Value
            $SourcePort = $RegexResults.Matches.Groups[6].Value
            
            Write-Debug "Logon Type: $LogonType"
            Write-Debug "Account Name: $AccountName"
            Write-Debug "Account Domain: $AccountDomain"
            Write-Debug "Logon ID: $LogonID"
            Write-Debug "Source Network Address: $SourceNetworkAddress"
            Write-Debug "Source Port: $SourcePort"
        }
        #endregion Extract data from log

        #Define interesting login types
        $InterestingLogonTypes = @(
            '2', # Interactive
            '3', # Network
            '4', # Batch
            '7', # Unlock
            '9', # New credentials, ie RunAs
            '10', # RemoteInteractive, ie RDP
            '11', # Cached credentials (ie no network access)
            '12', # Cached credentials for network login (ie no network access)
            '13' # Cached credentials for unlock (ie no network access)
        )

        # If the logon type is one of the interesting types, add it to the list
        if ($InterestingLogonTypes -contains $LogonType) {
            Write-Verbose "Interesting logon type found, adding to list"
            $NewElevatedLoginsToReturn = [PSCustomObject]@{
                Time     = $_.TimeGenerated
                LogonType = $LogonType
                AccountName = $AccountName
                AccountDomain = $AccountDomain
                LogonID = $LogonID
                SourceNetworkAddress = $SourceNetworkAddress
                SourcePort = $SourcePort
            }
            $ElevatedLoginsToReturn.Add($NewElevatedLoginsToReturn) | Out-Null
        }
        
    }

    return $ElevatedLoginsToReturn
    
}

#Get-UTSElevatedLogins | Format-Table
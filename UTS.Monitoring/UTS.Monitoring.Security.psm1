#$DebugPreference = $VerbosePreference = $InformationPreference = "Continue"
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

    Write-Verbose "Getting computer accounts to compare with"
    # Check if this is a computer account login
    if (Get-Command Get-ADComputer -ErrorAction Ignore) {
        $ADComputerAccounts = Get-ADComputer -Filter * | Select-Object SamAccountName
    } else {
        $ADComputerAccounts = @("")
    }

    $ElevatedLoginsToReturn = New-Object System.Collections.ArrayList

    # Loop through all found logins
    $ElevatedLogins | ForEach-Object {
        
        #region Extract data from log
        #region New Method: Extract from replacement strings
        $NewLogonSecurityID = $_.ReplacementStrings[4]
        $LogonType = [int]$_.ReplacementStrings[8]
        $AccountName = $_.ReplacementStrings[5]
        $AccountDomain = $_.ReplacementStrings[6]
        $LogonID = $_.ReplacementStrings[7]
        $SourceNetworkAddress = $_.ReplacementStrings[13]
        $SourcePort = $_.ReplacementStrings[14]
        
        Write-Debug "Event Index: $($_.Index)"
        Write-Debug "Logon Type: $LogonType"
        Write-Debug "Account Name: $AccountName"
        Write-Debug "Account Domain: $AccountDomain"
        Write-Debug "Logon ID: $LogonID"
        Write-Debug "Source Network Address: $SourceNetworkAddress"
        Write-Debug "Source Port: $SourcePort"

        
        #endregion New Method: Extract from replacement strings


        #endregion Extract data from log

        # Check if this is a system account login
        if ($NewLogonSecurityID -eq "S-1-5-18") {
            Write-Verbose "This is a system account login, skipping, login name was: [$AccountName]"
            # We use return because the ForEach-Object loop will continue to the next iteration using this rather than continue. This appears to be because its executed as a script block not a true loop.
            return
        }

        # Check if this is a computer account login
        if ($ADComputerAccounts -contains $AccountName) {
            Write-Verbose "This is a computer account login, skipping, login name was: [$AccountName]"
            # We use return because the ForEach-Object loop will continue to the next iteration using this rather than continue. This appears to be because its executed as a script block not a true loop.
            return
        }

        #Define interesting login types
        $InterestingLogonTypes = @{
            2 = "Interactive"
            3 = "Network"
            4 = "Batch"
            7 = "Unlock"
            9 = "New credentials, ie RunAs"
            10 = "RemoteInteractive, ie RDP"
            11 = "Cached credential login"
            12 = "Cached credentials for network login"
            13 = "Cached credentials for unlock"
        }

        # If the logon type is one of the interesting types, add it to the list
        if ($InterestingLogonTypes.ContainsKey($LogonType)) {
            Write-Verbose "Interesting logon type found, adding to list"
            $NewElevatedLoginsToReturn = [PSCustomObject]@{
                Time     = $_.TimeGenerated
                LogonType = $LogonType
                LogonTypeFriendlyName = $InterestingLogonTypes[$LogonType]
                AccountName = $AccountName
                AccountDomain = $AccountDomain
                LogonID = $LogonID
                SourceNetworkAddress = $SourceNetworkAddress
                SourcePort = $SourcePort
                Index = $_.Index
            }
            $ElevatedLoginsToReturn.Add($NewElevatedLoginsToReturn) | Out-Null
        }
        
    }

    return $ElevatedLoginsToReturn
    
}

#Get-UTSElevatedLogins | Format-Table
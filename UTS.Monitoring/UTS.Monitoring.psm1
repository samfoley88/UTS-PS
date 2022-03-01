# Including other files
Import-Module -Force -Name "$PSScriptRoot\UTS.Monitoring.Security.psm1"

function Get-UTSConnectivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$Target
    )
    
    $InitialStatus = Test-Connection $Target -Count 1 -Quiet
    if ($InitialStatus -eq $True) {
        Write-Output "$(Get-Date -UFormat "%Y-%m-%d | %T") |     $Target is currently online"
    } else {
        Write-Output "$(Get-Date -UFormat "%Y-%m-%d %T") $Target is currently offline"
    }

    $CurrentStatus = $InitialStatus

    While ($True) {
        $NewStatus = Test-Connection $Target -Count 1 -Quiet
        Write-Debug "$(Get-Date -UFormat "%Y-%m-%d %T") Debug: Current status: $Target is $NewStatus"

        if ($NewStatus -eq $CurrentStatus) {
            # Do nothing as status hasn't changed
        } else {
            if ($NewStatus -eq $True) {
                Write-Output "$(Get-Date -UFormat "%Y-%m-%d %T") $Target is now online"
            } else {
                Write-Output "$(Get-Date -UFormat "%Y-%m-%d %T") $Target is now offline"
            }
        }

        $CurrentStatus = $NewStatus
        Start-Sleep -Milliseconds 250
    }
   
}


function Test-UTSDomainConnectivity {
    <#
    .SYNOPSIS
        Test connectivity to the domain stepping through each possible issue type Basic DNS -> SRV -> Host resolution -> Trust test
    .OUTPUTS
        Write errors to Warning, and info and verbose to those respectively
    .EXAMPLE
        # To view the output of this function, use the following command
        $InformationPreference = $VerbosePreference = "Continue"
        Test-UTSDomainConnectivity
        
    #>
    [CmdletBinding()]
    param (
    )

    #region Define variables
    $Warning = [System.Collections.Generic.List[string]]::new()
    #endregion Definte variables

    #region Check all DNS Servers are private
    Write-Information "Checking DNS Servers are all private IPs"
    $DNSServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses -Unique
    Write-Verbose "DNS Servers are [$DNSServers]"
    Write-Verbose "Checking if those are private or public"
    $DNSServers | ForEach-Object {
        if (Test-UTSPrivateIP -IP $_) {
            Write-Verbose "$_ is a private IP"
        } else {
            $NewWarning = "$_ is a public IP"
            Write-Verbose $NewWarning
            $Warning = $Warning + $NewWarning
        }
    }
    Write-Information "Finished DNS Private IP Checks."

    #endregion Check all DNS Servers are private

    #region Check all DNS servers resolve the domain kerberos and ldap records
    Write-Information "Testing we can resolve domain controllers"
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    Write-Verbose "Domain is [$Domain]"
    Write-Verbose "Getting LDAP records"

    $LDAPRecords = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Domain" -Type SRV -ErrorAction "SilentlyContinue"
    if ($null -eq $LDAPRecords) {
        $NewWarning = "No LDAP Records found for domain [$Domain]"
        Write-Verbose $NewWarning
        $Warning = $Warning + $NewWarning
    } else {
        Write-Verbose "LDAP records found"
        $LDAPRecords | Where-Object {$null -ne $_.IP4Address} | ForEach-Object { 
            Test-Connection $_.IP4Address -Count 1 | Out-Null
        }
    }
    
    Write-Verbose "LDAP test completed"
    
    Write-Verbose "Getting kerberos records"

    $kerberosRecords = Resolve-DnsName -Name "_kerberos._tcp.dc._msdcs.$Domain" -Type SRV -ErrorAction "SilentlyContinue"
    if ($null -eq $kerberosRecords) {
        $NewWarning = "No kerberos Records found for domain [$Domain]"
        Write-Verbose $NewWarning
        $Warning = $Warning + $NewWarning
    } else {
        Write-Verbose "kerberos records found"
        $kerberosRecords | Where-Object {$null -ne $_.IP4Address} | ForEach-Object { 
            Test-Connection $_.IP4Address -Count 1 | Out-Null
        }
    }
    
    Write-Verbose "kerberos test completed"
    
    
    #endregion Check all DNS servers resolve the domain kerberos and kerberos records

    Write-Information "Finished testing domain controllers."

    Write-Information "Running final domain connection check"
    if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain){
        $SecureChannel = Test-ComputerSecureChannel -ErrorAction "SilentlyContinue"
        if ($SecureChannel -eq $false) {
            
            $NewWarning = "Test-ComputerSecureChannel failed"
            Write-Verbose $NewWarning
            $Warning = $Warning + $NewWarning
        }
        Write-Information "Final check finished."
    } else {
        Write-Information "Computer is not part of a domain, not running final check"
    }
        
    Write-Information "All checks are finished."

    if ($null -ne $Warning) {
        Write-Information "`n`n-------------------Warnings------------------"
        Write-Information "The following warnings were raised:"
        $WarningString = $Warning -Join "`n"
        Write-Information $WarningString
        Write-Information "------------------------------------------------`n`n"
        return $False
    } else {
        Write-Information "No warnings were raised, returning true"
        return $True
    }
}
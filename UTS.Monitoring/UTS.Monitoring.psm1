# $DebugPreference = $VerbosePreference = "Continue"

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
        Returns True or False based on whether the machine is successfully connected to a domain (or not domain joined at all). Warnings will also appear if you turn on output from the information stream.
        Writes all the results to the information feed (view from console with $InformationPreference = "Continue").
    .DESCRIPTION
        This function will test connectivity to the domain by stepping through each possible issue type.
        If any of the issues are found, the function will return False.
        If there are no issues, the function will return True.
    .EXAMPLE
        # To view the output of this function, use the following command
        $InformationPreference = $VerbosePreference = "Continue"
        Test-UTSDomainConnectivity
        
    #>
    [CmdletBinding()]
    param (
        # Fully qualified domain to check connectivity to if machine isn't domain joined
        [Parameter()]
        [string]
        $FQDN = ""
    )

    # If a domain is specified
    if ($FQDN -ne "") {
        $Domain = $FQDN
    } else {
        #Checking we are on a domain
        $SystemInfo = Get-WmiObject Win32_ComputerSystem
        if ($SystemInfo.DomainRole -in @(0,2)) {
            Write-Verbose "This computer is not joined to a domain and a FQDN has not been specified. Tests completed, exiting"
            return $True
        }
        $Domain = $SystemInfo.Domain
    }
    


    #region Check all DNS Servers are private
    Write-Information "Checking DNS Servers are all private IPs"
    $DNSServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses -Unique
    Write-Verbose "DNS Servers are [$DNSServers]"
    Write-Verbose "Checking if those are private or public"
    $DNSServers | ForEach-Object {
        if (Test-UTSPrivateIP -IP $_) {
            Write-Verbose "$_ is a private IP"
        } else {
            Write-UTSWarning "$_ is a public IP"
        }
    }
    Write-Information "Finished DNS Private IP Checks."

    #endregion Check all DNS Servers are private
    

    #region Check all DNS servers resolve the domain kerberos and ldap records
    Write-Information "Testing we can resolve domain controllers"
    
    Write-Verbose "Getting LDAP records"

    $LDAPRecords = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Domain" -Type SRV -ErrorAction "SilentlyContinue"
    if ($null -eq $LDAPRecords) {
        Write-UTSError "No LDAP Records found for domain [$Domain]"
    } else {
        Write-Verbose "LDAP records found"
        $LDAPRecords | Where-Object {$null -ne $_.IP4Address} | ForEach-Object { 
            $ConnectionTestResult = Test-Connection $_.IP4Address -Count 1 -ErrorAction "SilentlyContinue" -Quiet
            if ($ConnectionTestResult -eq $false) {
                Write-UTSError "LDAP Test: Cannot ping LDAP Server: [$($_.IP4Address)]"
            }
        }
    }
    
    Write-Verbose "LDAP test completed"
    
    Write-Verbose "Getting kerberos records"

    $kerberosRecords = Resolve-DnsName -Name "_kerberos._tcp.dc._msdcs.$Domain" -Type SRV -ErrorAction "SilentlyContinue"
    if ($null -eq $kerberosRecords) {
        Write-UTSError "No kerberos Records found for domain [$Domain]"
    } else {
        Write-Verbose "kerberos records found"
        $kerberosRecords | Where-Object {$null -ne $_.IP4Address} | ForEach-Object { 
            $ConnectionTestResult = Test-Connection $_.IP4Address -Count 1 -ErrorAction "SilentlyContinue" -Quiet
            if ($ConnectionTestResult -eq $false) {
                Write-UTSError = "kerberos Test: Cannot ping kerberos Server: [$($_.IP4Address)]"
            }
        }
    }
    
    Write-Verbose "kerberos test completed"    
    
    #endregion Check all DNS servers resolve the domain kerberos and kerberos records

    Write-Information "Finished testing domain controllers."

    Write-Information "Running final domain connection check"
    if ($SystemInfo.DomainRole -in @(0,2)) {
        Write-Verbose "This computer is not joined to a domain so not running Test-ComputerSecureChannel"
    } elseif ($SystemInfo.DomainRole -in @(5, 4)){
        Write-Verbose "This computer is a domain controller so not running Test-ComputerSecureChannel"
    } else {
        $SecureChannel = Test-ComputerSecureChannel -ErrorAction "SilentlyContinue"
        if ($SecureChannel -eq $false) {
            
            Write-UTSError "Test-ComputerSecureChannel failed"
        }
        Write-Information "Final check finished."
    }
        
    Write-Information "All checks are finished."

    return Invoke-UTSLogOutput

}
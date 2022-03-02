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
    )

    #region Define variables
    $Warning = [System.Collections.Generic.List[string]]::new()
    $OurCheckErrors = [System.Collections.Generic.List[string]]::new()
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
        $NewOurCheckError = "No LDAP Records found for domain [$Domain]"
        Write-Verbose $NewOurCheckError
        $OurCheckError = $OurCheckError + $NewOurCheckError
    } else {
        Write-Verbose "LDAP records found"
        $LDAPRecords | Where-Object {$null -ne $_.IP4Address} | ForEach-Object { 
            $ConnectionTestResult = Test-Connection $_.IP4Address -Count 1 -ErrorAction "SilentlyContinue" -Quiet
            if ($ConnectionTestResult -eq $false) {
                $NewOurCheckError = "LDAP Test: Cannot ping LDAP Server: [$($_.IP4Address)]"
                Write-Verbose $NewOurCheckError
                $OurCheckError = $OurCheckError + $NewOurCheckError
            }
        }
    }
    
    Write-Verbose "LDAP test completed"
    
    Write-Verbose "Getting kerberos records"

    $kerberosRecords = Resolve-DnsName -Name "_kerberos._tcp.dc._msdcs.$Domain" -Type SRV -ErrorAction "SilentlyContinue"
    if ($null -eq $kerberosRecords) {
        $NewOurCheckError = "No kerberos Records found for domain [$Domain]"
        Write-Verbose $NewOurCheckError
        $OurCheckError = $OurCheckError + $NewOurCheckError
    } else {
        Write-Verbose "kerberos records found"
        $kerberosRecords | Where-Object {$null -ne $_.IP4Address} | ForEach-Object { 
            $ConnectionTestResult = Test-Connection $_.IP4Address -Count 1 -ErrorAction "SilentlyContinue" -Quiet
            if ($ConnectionTestResult -eq $false) {
                $NewOurCheckError = "kerberos Test: Cannot ping kerberos Server: [$($_.IP4Address)]"
                Write-Verbose $NewOurCheckError
                $OurCheckError = $OurCheckError + $NewOurCheckError
            }
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
        $NewWarning = "The computer is not domain joined"
        Write-Verbose $NewWarning
        $Warning = $Warning + $NewWarning
        
    }
        
    Write-Information "All checks are finished."

    if ($Warning.Count -gt 0) {
        Write-Information "`n`n-------------------Warnings------------------"
        Write-Information "Warnings aren't necessarily something wrong but if you have domain related issues they should be fixed."
        Write-Information "The following warnings were raised:`n"
        $WarningString = $Warning -Join "`n"
        Write-Information $WarningString
        Write-Information "------------------------------------------------`n`n"
    } else {
        Write-Verbose "No warnings were raised"
    }

    if ($OurCheckErrors.Count -gt 0) {
        Write-Information "`n`n-------------------Errors------------------"
        Write-Information "These are errors, the domain is not working correctly for this device."
        Write-Information "The following errors were raised:`n"
        $OurCheckErrorsString = $OurCheckErrors -Join "`n"
        Write-Information $OurCheckErrorsString
        Write-Information "------------------------------------------------`n`n"
        return $False
    } else {
        Write-Information "No errors were raised, returning true"
        return $True
    }
}
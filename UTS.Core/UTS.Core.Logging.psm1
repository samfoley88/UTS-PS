# Debug variables
# $InformationPreference = "Continue"
# $VerbosePreference = "Continue"

# Create our module variables (if they don't exist)
$UTSErrors = [System.Collections.Generic.List[string]]::new()
$UTSWarnings = [System.Collections.Generic.List[string]]::new()

function Write-UTSError {
    <#
    .SYNOPSIS
        Writes to the UTS Error log
    .OUTPUTS
        Message is immediately written to the Verbose stream and stored for later processing
    .EXAMPLE
        Write-UTSError "This is an error message"
        
    #>
    [CmdletBinding()]
    param (
        # The message to write
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Value
    )
    Write-UTSLog -Value $Value -Log "Error"
}

function Write-UTSWarning {
    <#
    .SYNOPSIS
        Writes to the UTS Warning log
    .OUTPUTS
        Message is immediately written to the Verbose stream and stored for later processing
    .EXAMPLE
        Write-UTSWarning "This is an Warning message"
        
    #>
    [CmdletBinding()]
    param (
        # The message to write
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Value
    )
    Write-UTSLog -Value $Value -Log "Warning"
}
function Write-UTSLog {
    <#
    .SYNOPSIS
        Writes output to the UTS log variables and the verbose stream
    .OUTPUTS
        No direct output. Outputs the Logged message to the verbose stream
    .EXAMPLE
        Write-UTSLog -Value "Test Error Entry" -Log "Error"
        
    #>
    [CmdletBinding()]
    param (
        # The string to log
        [Parameter()]
        [string]
        $Value,
        # The type of log entry, current options "Error" and "Warning"
        [Parameter()]
        [string]
        $Log 
    )

    switch ($Log) {
        Error {
            $LogList = $UTSErrors
            $VerboseLoggingLabel = "UTS_ERROR"
          }
        Warning {
            $LogList = $UTSWarnings
            $VerboseLoggingLabel = "UTS_WARNING"
          }
        Default {
            throw "Invalid log type"
        }
    }
    
    Write-Verbose "$($VerboseLoggingLabel): $Value"
    $LogList.Add($Value)
}

function Invoke-UTSLogOutput {
    <#
    .SYNOPSIS
        Outputs any UTS log entries to Information stream and if required creates an RMM Alert.
    .OUTPUTS
        Returns False if there are any errors. Otherwise returns True.
        Warnings do NOT count as errors.
        Warning and Error details are outputted to the Information stream.
    .EXAMPLE
        Invoke-UTSLogOutput
        
    #>
    [CmdletBinding()]
    param (
        # Prevent the log variables from being reset
        [Parameter()]
        [switch]
        $PreventLogRest,
        # Specify the category of an RMM alert to generate. Defaults to not generating one.
        [Parameter()]
        [string]
        $RMMAlertCategory
    )
    

    if ($UTSWarnings.Count -gt 0) {
        Write-Information "`n-------------------Warnings------------------"
        Write-Information "The following warnings were raised:`n"
        $UTSWarningString = $UTSWarnings -Join "`n"
        Write-Information $UTSWarningString
        Write-Information "------------------------------------------------`n"
    } else {
        Write-Verbose "No warnings were raised"
    }

    if ($UTSErrors.Count -gt 0) {
        # Construct the error message
        $ErrorsMessage = ""
        $ErrorsMessage += "`n-------------------Errors------------------`n"
        $ErrorsMessage += "The following errors were raised:`n`n"
        $UTSErrorsString = $UTSErrors -Join "`n"
        $ErrorsMessage += $UTSErrorsString
        $ErrorsMessage += "`n------------------------------------------------`n"
        $ErrorsMessage += "Module version is: $(Get-Module UTS.Core | Select-Object -ExpandProperty Version | ForEach-Object { $_.ToString() })`n"
        # Output the error message
        Write-Information $ErrorsMessage
        
        # If required log the message to RMM
        if ((Get-Command RMM-Alert -ErrorAction "Ignore")) {
            if ($RMMAlertCategory -eq ""){
                Write-Debug "RMM alert category not set, setting to default 'Default Script Alert'"
                $RMMAlertCategory = "Default Script Alert"
            }
            Write-Debug "Detected Syncro Module and RMM Category, creating RMM Alert for errors"
            Rmm-Alert -Category $RMMAlertCategory -Body $ErrorsMessage
        }

        $ReturnValue = $False
    } else {
        Write-Information "No errors were raised, returning true"
        $ReturnValue = $True
    }



    if ($PreventResetLog -eq $False) {
        Write-Verbose "Resetting log"
        $UTSErrors = [System.Collections.Generic.List[string]]::new()
        $UTSWarnings = [System.Collections.Generic.List[string]]::new()
    }

    return $ReturnValue
}

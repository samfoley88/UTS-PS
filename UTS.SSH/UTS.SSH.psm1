#$InformationPreference = "Continue"
#$VerbosePreference = "Continue"
#$DebugPreference = "Continue"

function Invoke-UTSSSHCommand {
    <#
    .SYNOPSIS
        Invokes a command (or set of commands) on a remote machine using SSH.
    .OUTPUTS
        True if the command was successful, false otherwise.
    .EXAMPLE
        Invoke-UTSSHCommand -ComputerName "mymachine" -Command "ls -al" -SSHUser "ubuntu" -SSHKey "C:\users\myuser\mykey.pem"
    #>
    param (
        # The name/IP of the target
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName,
        # SSH username to use
        [Parameter()]
        [string]
        $SSHUser,
        # SSH password to use
        [Parameter()]
        [string]
        $SSHPassword,
        # SSH Key to use
        [Parameter()]
        [string]
        $SSHKey,
        # Single command to execute
        [Parameter()]
        [string]
        $SingleCommand,
        # Array of commands to execute
        [Parameter()]
        [System.Collections.Generic.List[string]]
        $CommandList,
        # Automatically approve the host key
        [Parameter()]
        [switch]
        $AutoApproveHostKey

    )
    
    #region Creating session
    Write-Verbose "Creating session"
    $SSHSessionParams = @{
        ComputerName = $ComputerName
    }
    if ($AutoApproveHostKey) {
        $SSHSessionParams.Add("AcceptKey", $true)
    }
    if ($SSHPassword) {
        Write-Verbose "Creating session with password"
        $SSHPassword = ConvertTo-SecureString $SSHPassword -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($SSHUser, $SSHPassword)
        $session = New-SSHSession -Credential $Credential @SSHSessionParams
    } elseif ($SSHKey) {
        Write-Verbose "Creating session with key"
        $Credential = New-Object System.Management.Automation.PSCredential($SSHUser, (New-Object System.Security.SecureString))
        $session = New-SSHSession -Credential $Credential -KeyFile $SSHKey @SSHSessionParams
    }

    if (!$session) {
        Write-UTSError "Failed to create session. Error given was: $($Error.CategoryInfo)"
        Invoke-UTSLogOutput
        return $False
    }

    #endregion Creating session

    #region Executing commands
    if ($SingleCommand) {
        Write-Verbose "Converting single command to command array"
        $CommandList = New-Object System.Collections.Generic.List[string]
        $CommandList.Add($SingleCommand)
    } 

    foreach ($Command in $CommandList) {
        Write-Verbose "Executing command: [$Command]"
        $Result = Invoke-SSHCommand -SSHSession $session -Command $Command
        if ($Result.ExitStatus -eq 0) {
            Write-Verbose "Command executed successfully. Enable debug to see output"
            Write-Debug "############## Result begins ###############"
            Write-Debug "$($Result.Output)"
            Write-Debug "############## Result ends ###############"
        
        } else {
            Write-Verbose "Command failed with exit code: [$Result.ExitStatus]"
            Write-Verbose "Enable debug to see output"
            Write-Debug "############## Result begins ###############"
            Write-Debug "$($Result.Output)"
            Write-Debug "############## Result ends ###############"
            Write-UTSError "Command [$Command] failed with exit code: [$Result.ExitStatus]. Message was [$($Result.Output)]"
        }
    }

    #endregion Executing commands

    #region Cleanup and finalise
    Remove-SSHSession -SSHSession $session
    Invoke-UTSLogOutput
    #endregion Cleanup and finalise


}

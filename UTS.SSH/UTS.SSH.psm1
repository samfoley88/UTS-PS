$InformationPreference = "Continue"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

function Invoke-UTSSSHCommand {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        [Parameter()]
        [string]$SSHUser,
        [Parameter()]
        [string]$SSHPassword,
        [Parameter()]
        [string]$SSHKey,
        [Parameter()]
        [string]$SingleCommand,
        [Parameter()]
        [System.Collections.Generic.List[string]]$CommandList
    )
    
    #region Creating session
    Write-Verbose "Creating session"
    if ($SSHPassword) {
        Write-Verbose "Creating session with password"
        $SSHPassword = ConvertTo-SecureString $SSHPassword -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($SSHUser, $SSHPassword)
        $session = New-SSHSession -ComputerName $ComputerName -Credential $Credential
    } elseif ($SSHKey) {
        Write-Verbose "Creating session with key"
        $Credential = New-Object System.Management.Automation.PSCredential($SSHUser, (New-Object System.Security.SecureString))
        $session = New-SSHSession -ComputerName $ComputerName -Credential $Credential -KeyFile C:\Users\samfo\.ssh\multipass.openssh
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

function New-UTSUbuntuVM {
    <#
    .SYNOPSIS
        Create a new Ubuntu VM in Hyper-V.
    .DESCRIPTION
        This command creates a new Ubuntu VM in Hyper-V.
        The VM creates a local user and a user using our default SSH key, you will need to modify the SSH key in the iso to use your own
        The password hash for the local recovery user is not secure and should be updated.
    .OUTPUTS
        Doesn't return anything, only for interactive use (currently)
    .EXAMPLE
        New-UTSUbuntuVM -Name "MyUbuntuVM"
        # Then go to Hyper-V and open the console. It will load to a screen where the bottom few lines include an intrusction to type yes to proceed with unattended installation. Do so!
        
    #>
    param (
        # The name of the VM to create
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        # The location to place the VM files
        [Parameter()]
        [string] 
        $Path = "C:\Hyper-V",
        # The unattend ISO to use (if not default)
        [string] 
        $UnattendISO = "$env:ProgramFiles\WindowsPowerShell\Modules\Files\DefaultUbuntuUnattend.iso",
        # The install ISO to use (if not default)
        [string]
        $InstallISO = "",
        # The memory size (if not default)
        [int64]
        $MemoryBytes = 2GB,
        # The switch to use (if not default)
        [string]
        $Switch = "External Switch",
        # vCPU Cores to assign
        [int]
        $Cores = 2
    )
    
    if ($InstallISO -eq "") {
        Write-Verbose "No ISO specified, requesting download"
        $InstallISO = $env:TEMP + "\ubuntu-install.iso"
        $DownloadURL = "https://releases.ubuntu.com/20.04.4/ubuntu-20.04.4-live-server-amd64.iso"

        Get-UTSFileFromInternet -SourceURL $DownloadURL -DestinationFile $InstallISO
    }
    
    # Get the switch you want to use if on another machine
    # Get-VMSwitch  * | Format-Table Name
    # Name the VM
    New-VM -Name $Name -MemoryStartupBytes $MemoryBytes -BootDevice VHD -NewVHDPath "$Path\Virtual Hard Disks\$Name.vhdx" -Path "$Path\VM Files" -NewVHDSizeBytes 40GB -Generation 2 -Switch $Switch
    Add-VMDvdDrive -VMName $Name -Path $InstallISO
    $DvdDrive = Get-VMDvdDrive -VMName $Name -ControllerLocation 1
    Set-VMFirmware -VMName $Name -FirstBootDevice $DvdDrive -EnableSecureBoot "Off"
    Add-VMDvdDrive -VMName $Name -Path $UnattendIso
    Set-VMProcessor -VMName $Name -Count 2

    Start-VM -VMName $Name
}
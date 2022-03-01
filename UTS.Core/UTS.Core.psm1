#region Create Module Variable Hashtable
$UTSCoreVariables = [ordered]@{
    UTSDataStorePath           = "$($env:ProgramFiles)\UTS\DataStore";
    ClientUsername      = 'username'
}
New-Variable -Name UTSCoreVariables  -Value $UTSCoreVariables -Scope Script -Force
#endregion Create Module Variable Hashtable

#region Create required elements for core functionality
New-Item -ItemType Directory -Force -Path $UTSCoreVariables.UTSDatastorePath | Out-Null

#region Create required elements for core functionality



function Get-UTSInstalled {
    [CmdletBinding()]
    param (
        
    )
    
    return $True
}

function Update-UTSPS {
    [CmdletBinding()]
    param (
        
    )
    
    #region Define variables
    $PowerShellModulesFolder = "$env:ProgramFiles\WindowsPowerShell\Modules"
    #endregion Define variables

    #region Check Access
    Write-Verbose "Checking for write access to modules folder"
    Write-Debug "Checking access for by writing [$PowerShellModulesFolder\WritePermissionsTest.txt]"
    
    try { 
        Out-File -FilePath "$PowerShellModulesFolder\WritePermissionsTest.txt"
        Remove-Item -Path "$PowerShellModulesFolder\WritePermissionsTest.txt"
    }
    catch {
        Write-Error "No write access to modules folder"
        exit 2
    }
    #endregion Check Access

    #region Download and unzip release
    Write-Information "Downloading the latest version of UTS-PS to the PowerShell module directory"
    $repo = "samfoley88/UTS-PS"

    $releases = "https://api.github.com/repos/$repo/releases"

    Write-Verbose "Changing PS to use updated (more secure) SSL settings to allow connection"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Verbose "Getting the latest release from GitHub"
    $tag = (Invoke-WebRequest -UseBasicParsing $releases | ConvertFrom-Json)[0].tag_name
    Write-Information "Latest release tag is $tag"
    $download = "https://github.com/$repo/archive/refs/tags/$tag.zip"


    Write-Verbose "Deleting existing zip file (if it exists)"
    Remove-Item -Path $Env:TEMP\$tag.zip -Force -ErrorAction SilentlyContinue
    Write-Verbose "Dowloading latest release"
    Invoke-WebRequest -UseBasicParsing $download -Out $Env:TEMP\$tag.zip

    Write-Verbose "Checking size of file"
    $size = (Get-Item -Path $Env:TEMP\$tag.zip).Length
    $sizeMB = $size / 1MB
    Write-Verbose "File size is $size bytes, which is $sizeMB MB"

    Write-Verbose "Removing old zip folder (if it exists)"
    Remove-Item -Path $ENV:TEMP\UTS-PS-$tag -Force -Recurse -ErrorAction SilentlyContinue
    Write-Verbose "Extracting zip file to temp folder"
    Expand-Archive -Path $Env:TEMP\$tag.zip -Force -DestinationPath $ENV:TEMP\UTS-PS-$tag
    #endregion Download and unzip release
    
     #region Update version number
     # Remove v from tag because its not part of the version number itself
     $versionNumber = $tag.replace('v','')
     Write-Verbose "Updating version number in module manifests"
     $psd1Files = Get-ChildItem $ENV:TEMP\UTS-PS-$tag -Filter *.psd1 -Recurse
     Write-Debug "Found module manifests: [$psd1Files]"
     $psd1Files | Foreach-Object {
         Write-Debug "Getting module manifest from [$_.FullName]"
         $OriginalManifest = get-content -Path $_.FullName -Raw
         Write-Debug "Updating manifst version number to [$versionNumber]"
         $UpdatedManifest = $OriginalManifest -replace "0.0.0",$versionNumber
         Write-Debug "Outputting updated manifest to [$_.FullName]"
         # Write-Host $UpdatedManifest
         Set-Content -Path $_.FullName -Value $UpdatedManifest
     }
     
     #endregion Update version number

    #region Copy files to module folder
    Write-Verbose "Clearing out [$PSModuleFolder] of all items starting 'UTS.'"
    Get-ChildItem -Path $PowerShellModulesFolder -Directory | Where-Object {$_.Name -match "^UTS\."} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    Write-Verbose "Copying modules to [$PowerShellModulesFolder] folder"
    Get-ChildItem -Path "$ENV:TEMP\UTS-PS-$tag\UTS-PS-$versionNumber\" -Directory | Where-Object {$_.Name -notmatch "^\."} | Copy-Item -Destination $PowerShellModulesFolder -Recurse
    
    Write-Verbose "Forcing update of all UTS modules loaded in the current session"
    Get-Module UTS* | Import-Module -Force
    Write-Information "UTS modules updated, new version is: $tag"
    Write-Information "To update active modules in this session run the below command."
    Write-Information "Get-Module UTS* | Import-Module -Force"
    #endregion Copy files to module folder

   
}

# 
function Get-UTSUnprocessed {
    <#
    .SYNOPSIS
        Deduplicates the provided list of objects against a file stored in json
    .OUTPUTS
        Returns a collection of objects that are not duplicates
    .EXAMPLE
        $TestArray = Get-ChildItem -Path C:\
        Get-UTSUnprocessed -Array $TestArray -FilteringProperty Name -UniqueHistoryId "Test"
        
    #>

    [CmdletBinding()]
    param (
        # Our array of objects to deduplicate
        [Parameter(Mandatory=$True)]
        [array]
        $Array,
        # The property in the input object to use to deduplicate
        [Parameter(Mandatory=$True)]
        [string]
        $FilteringProperty,
        # A unique identifier for this deduplication store, must be unique across this machine
        [Parameter()]
        [string]
        $UniqueHistoryId,
        # An optional path to a non-standard history file location
        [Parameter()]
        [string]
        $HistoryFile
    )

    #region Define variables
    if ($HistoryFile -eq "") {
        $HistoryFile = "$($UTSCoreVariables.UTSDatastorePath)\ProcessingHistory\$UniqueHistoryId.json"
    } elseif (($null -eq $HistoryFile) -and ($UniqueHistoryId -eq $null)) {
        Write-Error "Must provide either a history file or a unique history id"
        exit 2
    }
    #endregion Define variables

    #region Check if history file exists
    Write-Debug "Checking if history file exists"
    if (Test-Path -Path $HistoryFile) {
        Write-Debug "History file exists"
        #region Get history
        Write-Debug "Getting history"
        $HistoryFileRaw = Get-Content -Path $HistoryFile -Raw
        Write-Debug "History raw file is: [$HistoryFileRaw]"
        if ($null -eq $HistoryFileRaw) {
            Write-Debug "History file is empty"
            $History = New-Object System.Collections.Generic.List[Hashtable]
        } else {
            Write-Debug "History file is not empty"
            $History = ConvertFrom-Json $HistoryFileRaw
            # Remove unwanted object nesting if exists
            if ($null -ne $History.value){
                $History = $History.value
            }
        }
        #endregion Get history
    } else {
        Write-Debug "History file does not exist"
        Write-Information "Creating history file"
        New-Item -Path $HistoryFile -ItemType File -Force
        Write-Information "Creating blank history property"
        $History =  New-Object System.Collections.Generic.List[Hashtable]
    }
    #endregion Check if history file exists

    

    #region Compare new to old, remove old from new array and add new to old history
    # Process each item in new array and see if its FilterProperty is in the history
    # Process each item in new array and see if its FilterProperty is in the history
    $NewItems = New-Object System.Collections.Generic.List[Hashtable]
    
    Write-Debug "Comparing new array to history"
    foreach ($item in $Array) {
        Write-Debug "Checking if [$($item.$FilteringProperty)] is in history"
        if ($History -contains $item.$FilteringProperty) {
            Write-Debug "Found [$($item.$FilteringProperty)] in history"
        } else {
            Write-Debug "Did not find [$($item.$FilteringProperty)] in history"
            Write-Debug "Adding [$($item.$FilteringProperty)] to history"
            $History += $item.$FilteringProperty
            Write-Debug "Adding item to return array"
            $NewItems += $item
        }
    }
    #endregion Compare new to old, remove old from new array and add new to old history

    #endregion Compare new to old, remove old from new array and add new to old history
    



    #region Update history
    Write-Debug "Updating history"
    $UpdatedHistoryJson = ConvertTo-Json $History -Compress
    Write-Debug "Updated history is: [$UpdatedHistoryJson]"
    Write-Information "Writing history to file"
    Set-Content -Path $HistoryFile -Value $UpdatedHistoryJson
    #endregion Update history

    #region Return deduplicated array
    return $NewItems
    #endregion Return deduplicated array

}
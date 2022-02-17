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
    $UTSModuleFolder = "$env:ProgramFiles\WindowsPowerShell\Modules\UTS"
    #endregion Define variables

    #region Check Access
    Write-Debug "Creating modules folder if it doesn't exist"
    New-Item -ItemType Directory -Force -Path $UTSModuleFolder

    Write-Verbose "Checking for write access to modules folder"
    Write-Debug "Checking access for by writing [$UTSModuleFolder\WritePermissionsTest.txt]"
    
    try { 
        Out-File -FilePath "$UTSModuleFolder\WritePermissionsTest.txt"
        Remove-Item -Path "$UTSModuleFolder\WritePermissionsTest.txt"
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

    Write-Verbose "Getting the latest release from GitHub"
    $tag = (Invoke-WebRequest -UseBasicParsing $releases | ConvertFrom-Json)[0].tag_name
    Write-Information "Latest release tag is $tag"
    $download = "https://github.com/$repo/archive/refs/tags/$tag.zip"


    Write-Verbose "Deleting existing zip file (if it exists)"
    Remove-Item -Path $Env:TEMP\$tag.zip -Force -ErrorAction SilentlyContinue
    Write-Verbose "Dowloading latest release"
    Invoke-WebRequest -UseBasicParsing $download -Out $Env:TEMP\$tag.zip

    Write-Verbose "Removing old zip folder (if it exists)"
    Remove-Item -Path $ENV:TEMP\UTS-PS-$tag -Force -Recurse -ErrorAction SilentlyContinue
    Write-Verbose "Extracting zip file to temp folder"
    Expand-Archive -Path $Env:TEMP\$tag.zip -Force -DestinationPath $ENV:TEMP\UTS-PS-$tag
    #endregion Download and unzip release
    
    #region Copy files to module folder
    Write-Verbose "Clearing out target folder at $UTSModuleFolder\*"
    Remove-Item -Path $UTSModuleFolder\* -Force -Recurse -ErrorAction SilentlyContinue
    # Remove v from tag because its not there in folder
    $versionNumber = $tag.replace('v','')
    Write-Verbose "Copying module to target folder"
    Copy-Item -Path "$ENV:TEMP\UTS-PS-$tag\UTS-PS-$versionNumber\*" -Destination $UTSModuleFolder\ -Recurse
    #endregion Copy files to module folder

    #region Update version number
    Write-Verbose "Updating version number in module manifests"
    $psd1Files = Get-ChildItem $UTSModuleFolder -Filter *.psd1 -Recurse
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
}


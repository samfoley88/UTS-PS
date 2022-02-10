Write-Information "Downloading the latest version of UTS-PS to the PowerShell module directory"
$repo = "samfoley88/UTS-PS"

$releases = "https://api.github.com/repos/$repo/releases"

Write-Verbose "Getting the latest release from GitHub"
$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name
Write-Information "Latest release tag is $tag"
$download = "https://github.com/$repo/archive/refs/tags/$tag.zip"


Write-Verbose "Deleting existing zip file (if it exists)"
Remove-Item -Path $Env:TEMP\$tag.zip -Force -ErrorAction SilentlyContinue
Write-Verbose "Dowloading latest release"
Invoke-WebRequest $download -Out $Env:TEMP\$tag.zip

Write-Verbose "Removing old zip folder (if it exists)"
Remove-Item -Path $ENV:TEMP\UTS-PS-$tag -Force -Recurse -ErrorAction SilentlyContinue
Write-Verbose "Extracting zip file to temp folder"
Expand-Archive -Path $Env:TEMP\$tag.zip -Force -DestinationPath $ENV:TEMP\UTS-PS-$tag
Write-Verbose "Clearing out target folder at $env:ProgramFiles\WindowsPowerShell\Modules\UTS\*"
Remove-Item -Path $env:ProgramFiles\WindowsPowerShell\Modules\UTS\* -Force -Recurse -ErrorAction SilentlyContinue
# Remove v from tag because its not there in folder
$versionNumber = $tag.replace('v','')
Write-Verbose "Copying module to target folder"
Copy-Item -Path "$ENV:TEMP\UTS-PS-$tag\UTS-PS-$versionNumber\*" -Destination $env:ProgramFiles\WindowsPowerShell\Modules\UTS -Recurse


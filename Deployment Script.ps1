# Download latest dotnet/codeformatter release from github

$repo = "samfoley88/UTS-PS"
$file = "UTS-PS.zip"

$releases = "https://api.github.com/repos/$repo/releases"

Write-Host Determining latest release
$Json = Invoke-WebRequest $releases
$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name
# https://github.com/samfoley88/UTS-PS/archive/refs/tags/v0.0.1.zip
# $download = "https://github.com/$repo/releases/download/$tag/$file"
$download = "https://github.com/$repo/archive/refs/tags/$tag.zip"


# Delete existing zip file
Remove-Item -Path $Env:TEMP\$tag.zip -Force -ErrorAction SilentlyContinue
Write-Host Dowloading latest release
Invoke-WebRequest $download -Out $Env:TEMP\$tag.zip

Remove-Item -Path $ENV:TEMP\UTS-PS-$tag -Force -Recurse -ErrorAction SilentlyContinue
Write-Host Extracting release files
Expand-Archive -Path $Env:TEMP\$tag.zip -Force -DestinationPath $ENV:TEMP\UTS-PS-$tag
# Clear out target folder
Remove-Item -Path $env:ProgramFiles\WindowsPowerShell\Modules\UTS\* -Force -Recurse -ErrorAction SilentlyContinue
# Remove v from tag because its not there in folder
$versionNumber = $tag.replace('v','')
Copy-Item -Path "$ENV:TEMP\UTS-PS-$tag\UTS-PS-$versionNumber\*" -Destination $env:ProgramFiles\WindowsPowerShell\Modules\UTS -Recurse


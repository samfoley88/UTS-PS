UTS-PS

# Basic working
## Update modules while testing
```powershell
$UTSModuleFolder = "C:\Repos\UTS-PS\"
Get-ChildItem $UTSModuleFolder -Filter *.psd1 -Recurse | ForEach-Object { Import-Module -Force -Name $_.FullName }
```
# Adding a function/Module
### Function
- Make sure to add it to FunctionsToExport in the psd1
- If adding a file remember to add it to FileList in the psd1

### Module
- Use New-ModuleManifest to make the new module manifest, run the below from the Repo root. You will then need to open the psd1 and change the format to utf-8
```powershell
$ModuleName = "UTS.Snippets" ; New-Item .\$ModuleName -ItemType Directory ; New-ModuleManifest -ModuleVersion '0.0.0' -Author 'Sam Foley' -CompanyName 'Unified Technical Solutions Ltd' -Copyright '(c) 2022 Unified Technical Solutions Ltd. All rights reserved.' -ProjectUri 'https://github.com/samfoley88/UTS-PS' -RootModule "$ModuleName.psm1" -Path .\$ModuleName\$ModuleName.psd1 ; New-Item -Path ".\$ModuleName\$ModuleName.psm1" 
```
Nested modules can be imported using this in the main module file:
```powershell
Import-Module -Force -Name "$PSScriptRoot\UTS.Monitoring.Security.psm1"
```

# Code conventions
For logging use the following for the specific purpose
| Command | Used for |
| --- | ----------- |
| Write-Output | Output that needs to be pipable, other options may be better, to Google! |
| Write-Information | Basic high level information, for instance "beginning process" etc |
| Write-Progress | Used to provide the user with feedback on longer running operations, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-progress |
| Write-Verbose | Lower level logging but still potentially useful to an everyday user or us in everyday work, ie "Updating file x with new name x"|
| Write-Debug | Low level debug commands for instance "Setting variable X to [x]" |
| Write-Warning | A non blocking warning that the user should be aware of |
| Write-Error | A fatal error that cannot be overcome without the user changing something |
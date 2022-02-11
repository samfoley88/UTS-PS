UTS-PS

# Basic working
## Update modules while testing
```powershell
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
- NestedModules in the manifest might be needed but not sure. RequiredModules will confirm modules exist in the global session state so is probably what we want.
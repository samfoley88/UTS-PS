UTS-PS

# Adding a function/Module
### Function
- Make sure to add it to FunctionsToExport in the psd1
- If adding a file remember to add it to FileList in the psd1

### Module
- Use New-ModuleManifest to make the new module manifest, run the below from the Repo root
```powershell
$ModuleName = "UTS.Monitoring" ; New-Item .\$ModuleName -ItemType Directory ; New-ModuleManifest -ModuleVersion '0.0.0' -Author 'Sam Foley' -CompanyName 'Unified Technical Solutions Ltd' -Copyright '(c) 2022 Unified Technical Solutions Ltd. All rights reserved.' -ProjectUri 'https://github.com/samfoley88/UTS-PS' -RootModule "$ModuleName.psm1" -Path .\$ModuleName\$ModuleName.psd1 ; New-Item -Path ".\$ModuleName\$ModuleName.psm1" 
```
- NestedModules in the manifest might be needed but not sure. RequiredModules will confirm modules exist in the global session state so is probably what we want.
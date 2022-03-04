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
$ModuleName = "UTS.Snippets"
New-Item .\$ModuleName -ItemType Directory ; New-ModuleManifest -ModuleVersion '0.0.0' -Author 'Sam Foley' -CompanyName 'Unified Technical Solutions Ltd' -Copyright '(c) 2022 Unified Technical Solutions Ltd. All rights reserved.' -ProjectUri 'https://github.com/samfoley88/UTS-PS' -RootModule "$ModuleName.psm1" -Path .\$ModuleName\$ModuleName.psd1 ; New-Item -Path ".\$ModuleName\$ModuleName.psm1" 
```
Nested modules can be imported using this in the main module file:
```powershell
Import-Module -Force -Name "$PSScriptRoot\UTS.Monitoring.Security.psm1"
```

# Code conventions
## Logging commands
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

## Function commenting
- Add this after the start of the function:
```powershell
<#
    .SYNOPSIS
        Deduplicates the provided list of objects against a file stored in json
    .OUTPUTS
        Returns a collection of objects that are not duplicates
    .EXAMPLE
        $TestArray = Get-ChildItem -Path C:\
        Get-UTSUnprocessed -Array $TestArray -FilteringProperty Name -UniqueHistoryId "Test"
        
    #>
```
And a comment line before each paramater.

# Repository Management
## Commit Messages
We follow the conventional commits and semantic versioning standards. Our Github repo automatically versions based on these. Those standards are available at:

https://semver.org/

https://www.conventionalcommits.org/en/v1.0.0/#specification

We REQUIRE a scope for the commit message. This should be either the function name or the module name if multiple functions have been changed.


The commit message format is:
```
<type>(Scope): <Short description>
<Long description>
```
**Type**
- *feat* - new feature
- *feat.part* - new feature worked on but not yet usable
- *fix* - a fix to an issue OR a non-breaking change
- *docs* - updates to documentation
- *chore* - changes that don't affect the code that aren't covered by the above

**Scope**

The function worked on, or if multiple functions are worked on the module name.

**Short description**

A short description of the changes made written in the paste tense!

These are compressed into release notes so bear that in mind when writing.

**Long description**

Optional to provide additional detail or context on the changes made.

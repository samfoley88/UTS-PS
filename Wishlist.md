Get and Set UTSError and Warning
- Backed by global variable
- Able to return errors in bulk
	- Needs option to reset once returned
- Needs internal option to throw to internal "alert" function that can throw to Syncro
- Additional Get-UTSErrorExists and Get-UTSWarningExists will be needed

Get and Set UTS Variables
- Needs default options (defined in function)
- Stored in registry with security to DAs and local system
- Multiple values in an entry to JSON? Or CSV array?

For Test-UTSDomainConnectivity
- Add -ErrorVariable to return errors (as string?)
	- NO - ErrorVariable is a built in PS functionality that we cannot use like this.
	- Instead pass a name as -ReturnErrors ReturnedErrors and create as variable using the below:
```powershell
$script:Boom = "Now"
$Boom
function TestFunction (){$Script:Boom2 = "NotNow"}
$Boom2
TestFunction
$Boom2
Write-Output $Boom3

New to use New-Variable though

```
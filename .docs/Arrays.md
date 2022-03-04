The best thing for arrays in PS is the List type, its efficient and provides the usually required functionality.

You need to create a list and specify the type of objects in the list

```powershell
# List of Hashtables
$History = New-Object System.Collections.Generic.List[Hashtable]
# List of strings
$Warning = [System.Collections.Generic.List[string]]::new()

# Add element
$CommandList.Add($SingleCommand)


```
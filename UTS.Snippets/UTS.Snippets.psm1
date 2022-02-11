function Get-UTSAllHistory {
    Get-Content (Get-PSReadlineOption).HistorySavePath
}
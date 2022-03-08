$VerbosePreference = "continue"
$DebugPreference = "Continue"
$InformationPreference = "Continue"

function Backup-UTSGrafanaAllDashboards {
    [CmdletBinding()]
    param (
        # The basic auth encoded credentials for the Grafana server (I got mine from giving insomnia a username and password)
        [Parameter()]
        [string]
        $BasicAuthEncoded,
        # The URL of the Grafana server (ie. http://grafana.example.com:3000)
        [Parameter()]
        [string]
        $GrafanaURL,
        # The path to the backup folder, defaults to current folder
        [Parameter()]
        [string]
        $BackupFolder = "./"

    )

    Write-Verbose "Creating backup folder"
    New-Item -Type Directory -Path $BackupFolder -Force -ErrorAction Ignore

    Write-Debug "Grafana URL is [$GrafanaURL]. Auth token not output to log file."
    Write-Verbose "Setting auth header"
    $headers=@{}
    $headers.Add("Authorization", "Basic $BasicAuthEncoded")
    Write-Verbose "Getting all dashboards"
    $response = Invoke-WebRequest -Uri "$GrafanaURL/api/search" -Method GET -Headers $headers
    Write-Verbose "Parsing response"
    # Set-Content -Value $response.Content -Path "ReturnedJson.json"
    $Dashboards = ConvertFrom-Json -InputObject $response.Content
    
    foreach ($Dashboard in $Dashboards) {
        Write-Verbose "Getting dashboard [$($Dashboard.title)] with id [$($Dashboard.id)] and uid [$($Dashboard.uid)]"
        $response = Invoke-WebRequest -Uri "$GrafanaURL/api/dashboards/uid/$($Dashboard.uid)" -Method GET -Headers $headers
        Write-Verbose "Writing raw dashboard to file"
        Set-Content -Value $response.Content -Path "./$($Dashboard.title)-unedited.json"

        Write-Verbose "Parsing response"
        # Set-Content -Value $response.Content -Path "ReturnedJson.json"
        $DashboardJson = ConvertFrom-Json -InputObject $response.Content

        # Write-Verbose "Editing dashboard"
        # $DashboardJson.Dashboard.id = $null

        Write-Verbose "Writing dashboard to file"
        $EditedJson = ConvertTo-Json $DashboardJson -Depth 100
        # $EditedJson = ConvertTo-Json -InputObject $DashboardJson.meta.psobject.BaseObject -Depth 100

        Write-Verbose "Writing dashboard [$($Dashboard.title)] to file"
        Set-Content -Value $EditedJson -Path "$BackupFolder/$($Dashboard.title).json"
    }


}
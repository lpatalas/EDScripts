[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [DateTime] $Since
)

$events = & "$PSScriptRoot\GetJournalEvents.ps1" `
    -EventTypes MissionAccepted, MissionCompleted, MissionAbandoned, MissionFailed `
    -Since $Since

$completedMissions = @($events | Where-Object event -ne MissionAccepted)
$events `
| Where-Object event -eq MissionAccepted `
| Where-Object {
    $missionID = $_.MissionID
    $completeEvent = $completedMissions | Where-Object { $_.MissionID -eq $missionID }
    $wasCompleted = $completeEvent.Count -gt 0
    return (-not $wasCompleted)
}

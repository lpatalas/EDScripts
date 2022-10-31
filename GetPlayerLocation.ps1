[CmdletBinding()]
param(
    [ValidateRange('Positive')]
    [Int32] $Count = 1
)

Set-StrictMode -Version Latest

$locationEventTypes = @(
    'ApproachBody'
    'Docked'
    'Liftoff'
    'Location'
    'SupercruiseEntry'
    'SupercruiseExit'
    'Touchdown'
)

& "$PSScriptRoot\GetJournalEvents.ps1" $locationEventTypes `
| Select-Object -ExpandProperty StarSystem -First $Count -Unique
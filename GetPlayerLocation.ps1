[CmdletBinding()]
param(
    [ValidateRange('Positive')]
    [Int32] $Count = 1
)

Set-StrictMode -Version Latest

$locationEventTypes = @(
    'ApproachBody'
    'CarrierJump'
    'Docked'
    'FSDJump'
    'Liftoff'
    'Location'
    'SupercruiseEntry'
    'SupercruiseExit'
    'Touchdown'
)

& "$PSScriptRoot\GetJournalEvents.ps1" -EventTypes $locationEventTypes `
| Select-Object -ExpandProperty StarSystem `
| Get-Unique `
| Select-Object -First $Count

[CmdletBinding()]
param(
    [ValidateRange('Positive')]
    [Int32] $Count = 1
)

Set-StrictMode -Version Latest

$journalDir = "C:\Users\$env:USERNAME\Saved Games\Frontier Developments\Elite Dangerous"
$journalFiles = @(
    Get-ChildItem $journalDir -Filter 'Journal.????-??-??T??????.??.log' `
    | Sort-Object Name -Descending
)

$locationEventNames = @(
    'ApproachBody'
    'Docked'
    'Liftoff'
    'Location'
    'SupercruiseEntry'
    'SupercruiseExit'
    'Touchdown'
)

$foundLocationCount = 0
$lastFoundLocation = $null

foreach ($journalFile in $journalFiles) {
    $events = Get-Content $journalFile | ConvertFrom-Json
    for ($i = $events.Count - 1; $i -gt 0; $i--) {
        $ev = $events[$i]
        if ($ev.event -in $locationEventNames) {
            if ($lastFoundLocation -ne $ev.StarSystem) {
                Write-Output $ev.StarSystem
                $lastFoundLocation = $ev.StarSystem

                $foundLocationCount++
                if ($foundLocationCount -eq $Count) {
                    return
                }
            }
        }
    }
}
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [String[]] $EventTypes
)

Set-StrictMode -Version Latest

$journalDir = "C:\Users\$env:USERNAME\Saved Games\Frontier Developments\Elite Dangerous"
$journalFiles = (
    Get-ChildItem $journalDir -Filter 'Journal.????-??-??T??????.??.log' `
    | Sort-Object Name -Descending
)

foreach ($journalFile in $journalFiles) {
    $events = Get-Content $journalFile | ConvertFrom-Json
    for ($i = $events.Count - 1; $i -gt 0; $i--) {
        $ev = $events[$i]

        if ($ev.event -in $EventTypes) {
            Write-Output $ev
        }
    }
}
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [String[]] $EventTypes,

    [DateTime] $Since
)

Set-StrictMode -Version Latest

$journalDir = "$env:USERPROFILE\Saved Games\Frontier Developments\Elite Dangerous"
$journalFiles = (
    Get-ChildItem $journalDir -Filter 'Journal.????-??-??T??????.??.log' `
    | Sort-Object Name -Descending
)

foreach ($journalFile in $journalFiles) {
    if ($Since) {
        if (-not ($journalFile.Name -match 'Journal.(\d{4}-\d{2}-\d{2}T\d{6})')) {
            Write-Error "Can't parse journal date for file $journalFile"
        }

        $journalDate = [datetime]::ParseExact($matches[1], "yyyy-MM-dd'T'HHmmss", $null)
        if ($journalDate -lt $Since) {
            return
        }
    }

    $events = Get-Content $journalFile | ConvertFrom-Json
    for ($i = $events.Count - 1; $i -gt 0; $i--) {
        $ev = $events[$i]

        if ($ev.event -in $EventTypes) {
            Write-Output $ev
        }
    }
}
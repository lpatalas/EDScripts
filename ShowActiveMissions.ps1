[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [DateTime] $Since
)

$activeMissions = & "$PSScriptRoot\GetActiveMissions.ps1" -Since $Since

$utcNow = [datetime]::UtcNow

function FormatTimeLeft($expiryDateTime) {
    $timeLeft = $expiryDateTime - $utcNow
    "{0}D {1:00}H {2:00}M" -f $timeLeft.Days, $timeLeft.Hours, $timeLeft.Minutes
}

$activeMissions `
| ForEach-Object {
    [pscustomobject]@{
        Name = $_.LocalisedName
        Faction = $_.Faction
        Reward = $_.Reward.ToString('#,#', [System.Globalization.CultureInfo]::InvariantCulture)
        Wing = if ($_.Wing) { '✓' } else { ' ' }
        'Time Left' = FormatTimeLeft $_.Expiry
    }
}
| Format-Table

[pscustomobject]@{
    'Total Count' = $activeMissions.Count
    'Total Reward' = $activeMissions.Reward | Measure-Object -Sum | ForEach-Object Sum
} | Format-List

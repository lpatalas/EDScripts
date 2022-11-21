[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [DateTime] $Since
)

& "$PSScriptRoot\GetJournalEvents.ps1" -EventTypes LoadGame -Since $Since `
| Sort-Object -Property timestamp `
| ForEach-Object {
    [pscustomobject]@{
        Date = $_.timestamp
        Balance = $_.Credits
    }
}
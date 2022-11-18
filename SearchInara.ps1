[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Buy', 'Sell')]
    [String] $Transaction,

    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete)
        $unescapedWord = $wordToComplete.Trim(' ', "'", '"')
        Import-Csv "$PSScriptRoot\commodities.csv" `
        | Where-Object { $_.Name -like "$unescapedWord*" } `
        | ForEach-Object { if ($_.Name -match '\s') { "'$($_.Name)'" } else { $_.Name } } `
    })]
    [Parameter(Mandatory)]
    [String] $Commodity,

    [String] $NearStarSystem,

    [ValidateSet(0, 1000, 2500, 5000, 10000, 50000)]
    [String] $MinimumSupplyDemand = 0,

    [switch] $Online
)

Set-StrictMode -Version Latest

if (-not $NearStarSystem) {
    $NearStarSystem = & "$PSScriptRoot\GetPlayerLocation.ps1"
}

$commodityId = Import-Csv -LiteralPath "$PSScriptRoot\commodities.csv" `
    | Where-Object Name -eq $Commodity `
    | Select-Object -ExpandProperty Id -First 1

if (-not $commodityId) {
    throw "Unknown commodity name: $Commodity"
}

$transactionParam = if ($Transaction -eq 'Buy') { '1' } else { '2' }
$nearStarSystemParam = [System.Web.HttpUtility]::UrlEncode($NearStarSystem)
$maxStarSystemDistance = 5000
$maxPriceAgeParam = 24 # pi5=24 (1 day)

$searchUrl = @(
    'https://inara.cz/elite/commodities/'
    "?pi1=$transactionParam"
    "&pi2=$commodityId"
    "&ps1=$nearStarSystemParam"
    "&pi10=1"
    "&pi11=$maxStarSystemDistance"
    "&pi3=1"
    "&pi9=0"
    "&pi4=0"
    "&pi5=$maxPriceAgeParam"
    "&pi12=0"
    "&pi7=$MinimumSupplyDemand"
    "&pi8=0"
) -join ''

if ($Online) {
    Start-Process -FilePath $searchUrl
    return
}

Write-Debug "Downloading data from: $searchUrl"
$wc = New-Object System.Net.WebClient
$html = $wc.DownloadString($searchUrl)

function RemoveTags($text) {
    $text -replace '<[^>]+>',''
}

function ParsePrice($text) {
    $price = [pscustomobject]@{
        MinimumPrice = $null
        MaximumPrice = $null
    }

    if ($text -match '([0-9,]+)\s*-\s*([0-9,]+)') {
        $price.MinimumPrice = [int]($matches[1])
        $price.MaximumPrice = [int]($matches[2])
    }
    elseif ($text -match '[0-9,]+') {
        $value = [int]($matches[0])
        $price.MinimumPrice = $value
        $price.MaximumPrice = $value
    }

    return $price
}

function ParseInt($text) {
    if ($text -match '[0-9,]+') {
        return [int]($matches[0])
    }
    else {
        return $null
    }
}

function ParseDecimal($text) {
    if ($text -match '[0-9,\.]+') {
        return [decimal]($matches[0])
    }
    else {
        return $null
    }
}

$matchedCells = $html `
    | Select-String -Pattern '<td[^>]+>(.+?)</td>' -AllMatches `
    | Select-Object -ExpandProperty Matches `
    | ForEach-Object { RemoveTags $_.Groups[1].Value }

$cellsPerRow = 7
$rowCount = $matchedCells.Count / $cellsPerRow
$fontIconRegex = '[\ue81d\ufe0e]'

for ($rowIndex = 0; $rowIndex -lt $rowCount; $rowIndex++) {
    $cellIndex = $rowIndex * $cellsPerRow
    $price = ParsePrice $matchedCells[$cellIndex + 5]

    [pscustomobject]@{
        Location = $matchedCells[$cellIndex] -replace $fontIconRegex,''
        PadSize = $matchedCells[$cellIndex + 1]
        StationDistance = ParseDecimal ($matchedCells[$cellIndex + 2])
        SystemDistance = ParseDecimal ($matchedCells[$cellIndex + 3])
        SupplyDemand = ParseInt ($matchedCells[$cellIndex + 4])
        MinimumPrice = $price.MinimumPrice
        MaximumPrice = $price.MaximumPrice
        PriceAge = $matchedCells[$cellIndex + 6]
    }
}


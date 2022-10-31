[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Buy', 'Sell')]
    [String] $Transaction,

    [Parameter(Mandatory)]
    [String] $Commodity,

    [String] $NearStarSystem = 'Sol',

    [ValidateSet(0, 1000, 2500, 5000, 10000, 50000)]
    [String] $MinimumSupplyDemand = 0
)

Set-StrictMode -Version Latest

$transactionParam = if ($Transaction -eq 'Buy') { '1' } else { '2' }
$commodityParam = switch ($Commodity) {
    'Bauxite' { 51 }
    'Gold' { 42 }
    'Silver' { 46 }
    'Tritium' { 10269 }
    default { throw "Unknown commodity name: $Commodity" }
}
$nearStarSystemParam = [System.Web.HttpUtility]::UrlEncode($NearStarSystem)
$maxStarSystemDistance = 5000
$maxPriceAgeParam = 24 # pi5=24 (1 day)

$searchUrl = @(
    'https://inara.cz/elite/commodities/'
    "?pi1=$transactionParam"
    "&pi2=$commodityParam"
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

    if ($text -match '([0-9,\.]+)\s*-\s*([0-9,\.]+)') {
        $price.MinimumPrice = [decimal]($matches[1])
        $price.MaximumPrice = [decimal]($matches[2])
    }
    elseif ($text -match '[0-9,\.]+') {
        $value = [decimal]($matches[0])
        $price.MinimumPrice = $value
        $price.MaximumPrice = $value
    }

    return $price
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
$fontIconRegex = '[\ue81d\ufe0e]'

for ($cell = 0; $cell -lt $matchedCells.Count; $cell += $cellsPerRow) {
    $price = ParsePrice $matchedCells[$cell + 5]

    [pscustomobject]@{
        Location = $matchedCells[$cell] -replace $fontIconRegex,''
        PadSize = $matchedCells[$cell + 1]
        StationDistance = ParseDecimal ($matchedCells[$cell + 2])
        SystemDistance = ParseDecimal ($matchedCells[$cell + 3])
        SupplyDemand = ParseDecimal ($matchedCells[$cell + 4])
        MinimumPrice = $price.MinimumPrice
        MaximumPrice = $price.MaximumPrice
        PriceAge = $matchedCells[$cell + 6]
    }
}


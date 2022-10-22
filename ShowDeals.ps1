[CmdletBinding()]
param(
    [String] $CurrentSystem = 'Sol'
)

Set-StrictMode -Version Latest

function Main {
    $offersToCheck = @(
        Buy 'Gold' 10000
        Buy 'Silver' 10000
        Buy 'Tritium' 30000
        Sell 'Bauxite' 40000
        Sell 'Tritium' 200000 -minimumDemand 0
    )

    GetMatchingOffers $offersToCheck `
    | Format-Table -AutoSize
}

function Buy($commodity, $price) {
    [pscustomobject]@{
        Transaction = 'Buy'
        Commodity = $commodity
        Price = $price
        MinimumSupplyDemand = 1000
    }
}

function Sell($commodity, $price, $minimumDemand = 1000) {
    [pscustomobject]@{
        Transaction = 'Sell'
        Commodity = $commodity
        Price = $price
        MinimumSupplyDemand = $minimumDemand
    }
}

function GetMatchingOffers($offersToCheck) {
    $offersChecked = 0

    foreach ($offer in $offersToCheck) {
        Write-Progress `
            -Activity 'Checking offers' `
            -Status "$($offer.Transaction) $($offer.Commodity) at $($offer.Price)" `
            -PercentComplete ([Math]::Clamp(($offersChecked * 100) / $offersToCheck.Count, 1, 100))
    
        $commodities = & "$PSScriptRoot\SearchInara.ps1" `
            -Transaction $offer.Transaction `
            -Commodity $offer.Commodity `
            -MinimumSupplyDemand $offer.MinimumSupplyDemand `
            -NearStarSystem $CurrentSystem
    
        $matchingCommodities = if ($offer.Transaction -eq 'Buy') {
            $commodities | Where-Object { $_.Price -le $offer.Price }
        }
        else {
            $commodities | Where-Object { $_.Price -ge $offer.Price }
        }
    
        $matchingCommodities `
        | ForEach-Object {
            [PSCustomObject]@{
                Tx = $offer.Transaction
                Commodity = $offer.Commodity
                Location = $_.Location
                Pad = $_.PadSize
                Distance = $_.SystemDistance
                'S/D' = $_.SupplyDemand
                Price = $_.Price
                Age = $_.PriceAge
            }
        }
    
        Start-Sleep -Seconds 2
        $offersChecked += 1
    }
}

Main

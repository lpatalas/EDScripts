[CmdletBinding()]
param(
    [String] $CurrentSystem,

    [switch] $PassThru
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

    $referenceSystem = if ($CurrentSystem) {
        $CurrentSystem
    }
    else {
        & "$PSScriptRoot\GetPlayerLocation.ps1"
    }

    $offers = GetMatchingOffers $offersToCheck $referenceSystem
    if ($PassThru) {
        $offers
    }
    else {
        $offers | Format-Table -AutoSize
    }
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

function GetMatchingOffers($offersToCheck, $referenceSystem) {
    $offersChecked = 0

    foreach ($offer in $offersToCheck) {
        Write-Progress `
            -Activity "Checking offers near $referenceSystem" `
            -Status "$($offer.Transaction) $($offer.Commodity) at $($offer.Price)" `
            -PercentComplete ([Math]::Clamp(($offersChecked * 100) / $offersToCheck.Count, 1, 100))
    
        $commodities = & "$PSScriptRoot\SearchInara.ps1" `
            -Transaction $offer.Transaction `
            -Commodity $offer.Commodity `
            -MinimumSupplyDemand $offer.MinimumSupplyDemand `
            -NearStarSystem $referenceSystem
    
        $matchingCommodities = if ($offer.Transaction -eq 'Buy') {
            $commodities | Where-Object { $_.MinimumPrice -le $offer.Price }
        }
        else {
            $commodities | Where-Object { $_.MaximumPrice -ge $offer.Price }
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
                Price = if ($_.MinimumPrice -ne $_.MaximumPrice) { "$($_.MinimumPrice) - $($_.MaximumPrice)" } else { $_.MaximumPrice.ToString() }
                Age = $_.PriceAge
            }
        }

        $offersChecked += 1
    }
}

Main

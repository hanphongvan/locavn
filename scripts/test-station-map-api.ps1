# Test API /api/stations/map — kiểm tra giá RON95 / Diesel trả về.
#
# Cách dùng nhanh:
#   . .\scripts\test-station-map-api.ps1                      # dot-source để load function
#   Test-StationPrices                                        # mặc định localhost:5111, take=50
#   Test-StationPrices -BrandKey petrolimex -Sample 10        # lọc theo brand, in 10 mẫu
#   Test-StationPrices -BaseUrl http://192.168.170.125:5112   # gọi qua proxy LAN
#   Test-StationPrices -Take 50 -ShowEmpty                    # xem cả trạm thiếu giá

function Test-StationPrices {
    [CmdletBinding()]
    param(
        [string]$BaseUrl = 'http://localhost:5111',
        [int]$Take = 50,
        [string]$BrandKey,
        [int]$Sample = 5,
        [switch]$ShowEmpty
    )

    $url = "$BaseUrl/api/stations/map?take=$Take"
    Write-Host "GET $url" -ForegroundColor Cyan

    try {
        $resp = Invoke-RestMethod -Uri $url -TimeoutSec 15
    } catch {
        Write-Host "✗ Request lỗi: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    $items = $resp.items
    if (-not $items) {
        Write-Host "✗ Response không có 'items' — kiểm tra route / status." -ForegroundColor Red
        return
    }

    if ($BrandKey) {
        $items = @($items | Where-Object { $_.brandKey -eq $BrandKey })
    }

    $total       = $items.Count
    $withRon95   = @($items | Where-Object { $null -ne $_.priceRon95 }).Count
    $withDiesel  = @($items | Where-Object { $null -ne $_.priceDiesel }).Count
    $withBoth    = @($items | Where-Object { $null -ne $_.priceRon95 -and $null -ne $_.priceDiesel }).Count
    $withNeither = @($items | Where-Object { $null -eq $_.priceRon95 -and $null -eq $_.priceDiesel }).Count

    Write-Host ""
    Write-Host "Tổng số trạm trả về : $total" -ForegroundColor White
    if ($BrandKey) { Write-Host "  (đã lọc brandKey = $BrandKey)" -ForegroundColor DarkGray }
    Write-Host "  có giá RON95     : $withRon95" -ForegroundColor Green
    Write-Host "  có giá Diesel    : $withDiesel" -ForegroundColor Green
    Write-Host "  có cả hai        : $withBoth"  -ForegroundColor Green
    Write-Host "  không có giá nào : $withNeither" -ForegroundColor $(if ($withNeither -eq 0) { 'Green' } else { 'Yellow' })

    if ($total -eq 0) {
        Write-Host "Không có trạm nào khớp tiêu chí." -ForegroundColor Yellow
        return
    }

    # Top mẫu: ưu tiên trạm có giá (hoặc tất cả nếu -ShowEmpty).
    $sampleSrc = if ($ShowEmpty) {
        $items
    } else {
        $items | Where-Object { $null -ne $_.priceRon95 -or $null -ne $_.priceDiesel }
    }

    Write-Host ""
    Write-Host "Mẫu $Sample dòng đầu :" -ForegroundColor White
    $sampleSrc |
        Select-Object -First $Sample stationId, stationName, brandKey,
            @{ N='RON95';  E={ if ($_.priceRon95)  { '{0:N0}' -f [decimal]$_.priceRon95  } else { '—' } } },
            @{ N='Diesel'; E={ if ($_.priceDiesel) { '{0:N0}' -f [decimal]$_.priceDiesel } else { '—' } } } |
        Format-Table -AutoSize
}

# Bonus: test 1 trạm cụ thể qua /api/stations/{id} để so chéo.
function Test-StationDetailPrice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$StationId,
        [string]$BaseUrl = 'http://localhost:5111'
    )
    $url = "$BaseUrl/api/stations/$StationId"
    Write-Host "GET $url" -ForegroundColor Cyan
    try {
        $r = Invoke-RestMethod -Uri $url -TimeoutSec 15
    } catch {
        Write-Host "✗ Request lỗi: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    [pscustomobject]@{
        StationId     = $r.stationId
        StationName   = $r.stationName
        PriceRon95    = if ($r.priceRon95)  { '{0:N0}' -f [decimal]$r.priceRon95  } else { '—' }
        PriceDiesel   = if ($r.priceDiesel) { '{0:N0}' -f [decimal]$r.priceDiesel } else { '—' }
        ParentDonViId = $r.parentDonViId
    } | Format-List
}

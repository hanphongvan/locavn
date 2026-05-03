using Httm.XangDau.Api.Shared.Reporting;

namespace Httm.XangDau.Api.Features.FuelReporting.Contracts;

/// <summary>
/// Price-oriented line: schema marks <c>LoaiGia</c> / <c>ThoiDiemDinhGia</c> as price signals; numeric meaning of <c>So_XX</c> is template-specific.
/// </summary>
public sealed record FuelPriceLineDto(
    int StationId,
    string? StationName,
    Guid ThongKeId,
    Guid LineId,
    string? MaSo,
    string? TenThongKe,
    int? LoaiGia,
    DateTime? ThoiDiemDinhGia,
    decimal? So01,
    decimal? So02,
    decimal? So03);

/// <summary>Latest prices across all stations with a report in the resolved period.</summary>
public sealed record LatestFuelPricesResponseDto(ReportingPeriodDto? Period, IReadOnlyList<FuelPriceLineDto> Items);

/// <summary>Price lines for one station (same period).</summary>
public sealed record StationFuelPricesResponseDto(
    ReportingPeriodDto? Period,
    int StationId,
    string? StationName,
    IReadOnlyList<FuelPriceLineDto> Items);

/// <summary>
/// Non-price detail line treated as quantity-oriented for demo stock (inferred: no <c>LoaiGia</c>/<c>ThoiDiemDinhGia</c>, at least one of <c>So_01..03</c> set).
/// </summary>
public sealed record FuelStockLineDto(
    Guid LineId,
    string? MaSo,
    string? TenThongKe,
    int? Nhom,
    decimal? So01,
    decimal? So02,
    decimal? So03);

public sealed record InventoryNhomGroupDto(int? Nhom, int LineCount, decimal? SumSo01);

/// <summary>Demo-level aggregate over stock-sliced detail lines in the period.</summary>
public sealed record InventorySummaryResponseDto(
    ReportingPeriodDto? Period,
    int ReportingStationCount,
    int StockLineCount,
    decimal? TotalSo01,
    IReadOnlyList<InventoryNhomGroupDto> ByNhom);

public sealed record StationInventoryResponseDto(
    ReportingPeriodDto? Period,
    int StationId,
    string? StationName,
    IReadOnlyList<FuelStockLineDto> Items);

/// <summary>Per-station snapshot for map markers (latest period, <c>So_01</c> as displayed unit price).</summary>
public sealed record MapStationPrices(decimal? PriceRon95, decimal? PriceDiesel);

/// <summary>Embedded in <c>GET /api/stations/{id}</c> when reporting exists.</summary>
public sealed record StationReportingPricesDto(ReportingPeriodDto? Period, IReadOnlyList<FuelPriceLineDto> Lines);

public sealed record StationReportingStockDto(
    ReportingPeriodDto? Period,
    int LineCount,
    decimal? TotalSo01,
    IReadOnlyList<FuelStockLineDto> Lines);

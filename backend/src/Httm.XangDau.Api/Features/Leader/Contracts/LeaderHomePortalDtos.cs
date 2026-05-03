namespace Httm.XangDau.Api.Features.Leader.Contracts;

/// <summary>Body aligned with legacy <c>DMPPortal</c> <c>api/dashboard/*</c> POST models.</summary>
public sealed record LeaderHomeDashboardRequest(
    string? UserName,
    string? DonViId,
    string? Period,
    int? Month,
    int? Year);

/// <summary>Tồn kho / nhập xuất / cân đối — tương đương <c>DashboardInventorySummaryDto</c> (Angular home).</summary>
public sealed record LeaderHomeInventorySummaryResponse(
    string DataSource,
    IReadOnlyList<LeaderHomeTongTonKhoRow> TongTonKho,
    IReadOnlyList<LeaderHomeNhapXuatRow> NhapXuat,
    IReadOnlyList<LeaderHomeCanDoiRow> CanDoi);

public sealed record LeaderHomeTongTonKhoRow(
    string Ten,
    string Dvt,
    decimal GiaTri,
    int SoNgay,
    string Type,
    IReadOnlyList<decimal> Trend);

public sealed record LeaderHomeNhapXuatRow(
    string Ten,
    string Dvt,
    string Type,
    decimal Nhap,
    decimal Xuat,
    decimal PctNhap,
    decimal PctXuat);

public sealed record LeaderHomeCanDoiRow(
    string Ten,
    string Dvt,
    string Type,
    decimal GiaTri,
    IReadOnlyList<decimal> Trend);

public sealed record LeaderHomeNationalStockMovementResponse(
    string DataSource,
    LeaderHomeNationalMovementChartDto? TonKhoChart,
    LeaderHomeNationalMovementChartDto? NhapXuatChart,
    LeaderHomeTonKhoVsPrevMonthDto? TonKhoVsPrevMonth,
    LeaderHomeNhapXuatVsPrevMonthDto? NhapXuatVsPrevMonth);

public sealed record LeaderHomeNationalMovementChartDto(
    IReadOnlyList<string> Labels,
    IReadOnlyList<LeaderHomeNationalMovementDatasetDto> Datasets);

public sealed record LeaderHomeNationalMovementDatasetDto(
    string Label,
    string? BorderColor,
    string? BackgroundColor,
    IReadOnlyList<decimal> Data);

public sealed record LeaderHomeTonKhoVsPrevMonthDto(decimal XangPct, decimal DauPct);

public sealed record LeaderHomeNhapXuatVsPrevMonthDto(decimal NhapPct, decimal XuatPct);

public sealed record LeaderHomePriceSummaryResponse(
    string DataSource,
    IReadOnlyList<LeaderHomePriceRow> Prices,
    LeaderHomePriceChartDto? PriceChart);

/// <param name="Class">JSON: <c>class</c> (camelCase từ <see cref="Class"/>).</param>
public sealed record LeaderHomePriceRow(
    string Name,
    decimal Value,
    decimal Change,
    string? Class,
    string Color);

public sealed record LeaderHomePriceChartDto(
    IReadOnlyList<string> Labels,
    string? NgayDinhGiaGanNhat,
    IReadOnlyList<LeaderHomePriceChartDatasetDto> Datasets);

public sealed record LeaderHomePriceChartDatasetDto(
    string Label,
    string BorderColor,
    IReadOnlyList<decimal> Data);

/// <summary>Điểm bản đồ đầu mối — tương đương <c>BC02Controller.get_bieudo_tonkho_daumoi</c>.</summary>
public sealed record LeaderHomeDistributorMapRequest(string? UserName, string? Ma);

public sealed record LeaderHomeDistributorMapRow(
    string Name,
    decimal Lat,
    decimal Lng,
    decimal Xang,
    decimal Dau,
    int Days);

public sealed record LeaderHomeDistributorMapResponse(string DataSource, IReadOnlyList<LeaderHomeDistributorMapRow> Items);

/// <summary>Chi tiết tồn kho theo đầu mối (<c>CapDonViId = 235</c>) — cùng nguồn <c>sp_Dashboard_Home_NationalInventoryDetailByUnit</c> như DMPPortal <c>national-inventory-detail-by-unit</c>.</summary>
public sealed record LeaderInventoryDetailResponse(
    string DataSource,
    string? ReportPeriodLabel,
    IReadOnlyList<LeaderInventoryDetailRow> Items);

/// <param name="FuelType"><c>gasoline</c> hoặc <c>oil</c>.</param>
/// <param name="StatusCode">Đồng bộ <c>fn_Leader_Map_DistributorReserveDisplayStatus</c>: <c>0</c> an toàn, <c>1</c> cảnh báo, <c>2</c> nguy cơ (từ <c>fn_Leader_InventoryReserveStatusByCoverageDays</c>).</param>
/// <param name="Status">Nhãn hiển thị do SQL trả về — có thể đổi trên máy chủ.</param>
public sealed record LeaderInventoryDetailRow(
    int DistributorId,
    string DistributorName,
    string? Address,
    string FuelType,
    decimal InventoryQuantity,
    string Unit,
    decimal CoverageDays,
    int StatusCode,
    string Status,
    DateTimeOffset UpdatedAt);

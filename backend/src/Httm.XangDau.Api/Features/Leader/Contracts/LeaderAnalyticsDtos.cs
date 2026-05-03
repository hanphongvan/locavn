namespace Httm.XangDau.Api.Features.Leader.Contracts;

/// <summary>Mobile Phân tích — đồng bộ logic biểu đồ với <c>sp_Dashboard_Home_NationalStockMovement</c> / <c>sp_Dashboard_Home_PriceSummary</c> (DMPPortal home).</summary>
public sealed record LeaderAnalyticsChartSeriesDto(string Label, string Color, IReadOnlyList<decimal> Values);

public sealed record LeaderAnalyticsInventoryTrendDto(
    string DataSource,
    IReadOnlyList<string> Labels,
    IReadOnlyList<LeaderAnalyticsChartSeriesDto> Series);

/// <param name="Fuel">Gợi ý: <c>xang</c> | <c>dau</c> — tách nhập/xuất theo tỷ trọng tồn Xăng/Dầu từng kỳ (ước lượng khi SP không tách dòng).</param>
public sealed record LeaderAnalyticsImportExportTrendDto(
    string DataSource,
    string Fuel,
    IReadOnlyList<string> Labels,
    IReadOnlyList<decimal> Nhap,
    IReadOnlyList<decimal> Xuat);

public sealed record LeaderAnalyticsPriceTrendDto(
    string DataSource,
    IReadOnlyList<string> Labels,
    string? NgayDinhGiaGanNhat,
    IReadOnlyList<LeaderAnalyticsCurrentPriceDto> CurrentPrices,
    IReadOnlyList<LeaderAnalyticsChartSeriesDto> Series);

public sealed record LeaderAnalyticsCurrentPriceDto(string Label, decimal Value, decimal Change);

public sealed record LeaderAnalyticsPeriodComparisonDto(
    string DataSource,
    LeaderAnalyticsDeltaCardDto TonKhoXang,
    LeaderAnalyticsDeltaCardDto TonKhoDau,
    LeaderAnalyticsDeltaCardDto Nhap,
    LeaderAnalyticsDeltaCardDto Xuat);

/// <param name="PctChange">Dương = tăng, âm = giảm, 0 = không đổi.</param>
public sealed record LeaderAnalyticsDeltaCardDto(string Title, decimal PctChange);

public sealed record LeaderAnalyticsMarketInsightDto(
    string DataSource,
    string XuHuongGia,
    string RuiRoCungCau,
    string KhuVucBatThuong,
    string DeXuat);

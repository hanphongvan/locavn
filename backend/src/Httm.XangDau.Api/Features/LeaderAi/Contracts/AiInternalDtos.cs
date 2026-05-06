namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

// === Request DTOs (AI Gateway → .NET) ===

public sealed record AiFuelInventoryRequest(
    int? RegionId,
    int? ProvinceId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    string? FuelType);

public sealed record AiFuelPriceRequest(
    string? FuelType,
    int? PeriodCount);

public sealed record AiInventoryByHeadOfficeRequest(
    int? RegionId,
    int? ProvinceId,
    string? FuelType,
    int? Top);

public sealed record AiStationDensityRequest(
    int? RegionId,
    int? ProvinceId);

public sealed record AiToolLogRequest(
    int UserId,
    string ToolName,
    string? InputJson,
    string? OutputJson,
    string Status,
    string? ErrorMessage,
    int? DurationMs);

// === Response DTOs (.NET → AI Gateway) — đúng output schema Section 11 ===

public sealed record AiFuelInventoryRow(
    string FuelType,
    decimal TotalStock,
    string StockUnit,
    decimal? PreviousPeriodStock,
    decimal? ChangePercent,
    decimal? MinSafeStock,
    bool IsLowStock,
    int? RegionId,
    string? RegionName,
    DateOnly AsOfDate);

public sealed record AiFuelPriceRow(
    string FuelType,
    int PeriodIndex,
    string PeriodLabel,
    DateOnly EffectiveDate,
    decimal Price,
    string PriceUnit,
    decimal? ChangeFromPrev);

public sealed record AiHeadOfficeRow(
    int HeadOfficeId,
    string HeadOfficeCode,
    string HeadOfficeName,
    string FuelType,
    decimal TotalStock,
    string StockUnit,
    decimal? MinSafeStock,
    bool IsLowStock,
    int RankNumber);

public sealed record AiStationDensityRow(
    int ProvinceId,
    string ProvinceCode,
    string ProvinceName,
    int? RegionId,
    string? RegionName,
    int StationCount,
    decimal? AreaKm2,
    decimal? DensityPer100Km2,
    string DensityCategory);

/// <summary>Wrapper response chuẩn — AI Gateway parse <c>rows</c> + verify status.</summary>
public sealed record AiInternalRowsResponse<T>(
    IReadOnlyList<T> Rows,
    int Count);

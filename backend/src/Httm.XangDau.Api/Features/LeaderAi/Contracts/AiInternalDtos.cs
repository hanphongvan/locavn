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

/// <summary>Phase 3 — AI Gateway POST mỗi 5 lượt để lưu summary tóm tắt.</summary>
public sealed record AiContextSummaryRequest(
    Guid ConversationId,
    int UserId,
    string Summary);

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
    DateOnly AsOfDate,
    int? DaysOfStock = null);

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
    int RankNumber,
    int? DaysOfStock = null);

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

// === Phase 5D — Schema Catalog (Section 8 + 14.4 của docs/loca-ai-phase5.md) ===

/// <summary>
/// Entry trả về cho AI Gateway từ <c>GET /internal/ai/schema-catalog</c>.
/// Các field JSON trong DB (<c>AllowedColumnsJson</c>, ...) đã được data access
/// deserialize sẵn để Python không phải parse lần nữa khi index Qdrant.
/// </summary>
/// <remarks>
/// Endpoint chỉ trả entity <c>IsEnabled = 1</c> nên DTO không expose field
/// <c>IsEnabled</c> (luôn true). Phase 5G nếu cần admin view sẽ tạo DTO riêng.
/// <para>
/// <see cref="AllowedJoins"/> phân biệt 2 trạng thái: <c>null</c> = entity không
/// khai báo joins (DB lưu SQL NULL); empty list = cấu hình rỗng có chủ đích
/// (DB lưu <c>"[]"</c>). Phase 5E SqlBuilder sẽ phân biệt 2 case này.
/// </para>
/// </remarks>
public sealed record SchemaCatalogEntryDto(
    string EntityCode,
    string DisplayName,
    string Description,
    string DataLayer,
    string BaseView,
    string PrimaryKey,
    IReadOnlyList<string> AllowedColumns,
    IReadOnlyList<string> AllowedFilters,
    IReadOnlyList<string> AllowedAggregates,
    IReadOnlyList<JoinSpecDto>? AllowedJoins,
    IReadOnlyList<string> SampleQuestions,
    int DefaultLimit,
    int MaxLimit,
    int SensitivityLevel,
    int RequiredRoleLoai,
    DateTime Created,
    DateTime? Modified);

/// <summary>
/// JSON shape của 1 entry trong <c>AiSchemaCatalog.AllowedJoinsJson</c>.
/// Vd: <c>{"view":"DM_Tinh","key":"TinhId = DM_Tinh.Id"}</c>.
/// </summary>
public sealed record JoinSpecDto(string View, string Key);

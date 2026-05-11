using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper data access cho 4 SP <c>sp_Ai_*</c> — AI Gateway gọi qua
/// <c>POST /internal/ai/*</c> ở Phase 2A.
/// </summary>
public interface IAiInternalDataAccess
{
    Task<IReadOnlyList<AiFuelInventoryRow>> GetFuelInventorySummaryAsync(
        AiFuelInventoryRequest request,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 2A bugfix — gọi <c>sp_Ai_GetRetailFuelInventorySummary</c> cho intent
    /// <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>. Khác <see cref="GetFuelInventorySummaryAsync"/>
    /// (đầu mối) ở chỗ đọc <c>StationInventoryTransaction*</c> + filter <c>FuelProducts.Code</c>.
    /// </summary>
    Task<IReadOnlyList<AiFuelInventoryRow>> GetRetailFuelInventorySummaryAsync(
        AiFuelInventoryRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AiFuelPriceRow>> GetFuelPriceTrendAsync(
        AiFuelPriceRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AiHeadOfficeRow>> GetInventoryByHeadOfficeAsync(
        AiInventoryByHeadOfficeRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AiStationDensityRow>> GetStationDensityByProvinceAsync(
        AiStationDensityRequest request,
        CancellationToken cancellationToken);

    /// <summary>INSERT 1 row vào <c>AiToolLogs</c> — phục vụ token usage logging Section 9.</summary>
    Task LogToolCallAsync(
        AiToolLogRequest request,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 3 — UPSERT <c>AiConversationContexts.LastAnswerSummary</c> theo
    /// <c>ConversationId</c>. AI Gateway gọi mỗi 5 lượt (Section 19.3).
    /// </summary>
    Task UpsertContextSummaryAsync(
        Guid conversationId,
        int userId,
        string summary,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 5D — đọc danh sách entity AI được phép từ <c>AiSchemaCatalog WHERE IsEnabled=1</c>.
    /// AI Gateway dùng để index Qdrant collection <c>ai_schema_catalog</c>
    /// (Section 14.4 của <c>docs/loca-ai-phase5.md</c>).
    /// </summary>
    Task<IReadOnlyList<SchemaCatalogEntryDto>> GetSchemaCatalogAsync(
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 5H — đọc kỳ (Nam, Thang) gần nhất của 1 entity snapshot.
    /// Query whitelist: chỉ entity có <c>IsSnapshot=1</c> trong AiSchemaCatalog
    /// (defense-in-depth ngừa SQL injection qua param entity); BaseView được map
    /// trực tiếp tên view thay vì interpolate user input.
    /// Trả <c>(null, null)</c> nếu view chưa có data hoặc entity không phải snapshot.
    /// </summary>
    Task<LatestPeriodDto> GetLatestPeriodAsync(
        string entityCode,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 5F — INSERT 1 row vào <c>AiDynamicQueryLogs</c>. Status enum khớp
    /// <c>CK_AiDynamicQueryLogs_Status</c>: success / plan_invalid / sql_invalid /
    /// safety_blocked / execution_failed / timeout / no_data.
    /// </summary>
    Task LogDynamicQueryAsync(
        AiDynamicQueryLogRequest request,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 5F → 5G self-improving — UPSERT vào <c>AiCandidateIntents</c> theo
    /// <c>QuestionFingerprint</c>. EXISTS: UsageCount + 1, SuccessCount + 1,
    /// LastUsedAt = SYSUTCDATETIME(). NOT EXISTS: INSERT mới với Status='pending'.
    /// </summary>
    Task UpsertCandidateIntentAsync(
        AiCandidateIntentUpsertRequest request,
        CancellationToken cancellationToken);
}

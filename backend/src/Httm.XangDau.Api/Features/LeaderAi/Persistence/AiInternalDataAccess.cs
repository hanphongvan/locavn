using System.Data;
using System.Text.Json;
using Dapper;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper implementation — gọi 4 SP <c>sp_Ai_*</c> + INSERT <c>AiToolLogs</c>
/// + đọc Schema Catalog cho Phase 5D.
/// </summary>
public sealed class AiInternalDataAccess(
    IConfiguration configuration,
    ILogger<AiInternalDataAccess> logger) : IAiInternalDataAccess
{
    /// <summary>
    /// Hàng đọc từ <c>sp_Ai_GetFuelInventorySummary</c> — Dapper map theo tên cột + setter;
    /// không map trực tiếp <see cref="AiFuelInventoryRow"/> (positional record: SqlClient trả <c>DATE</c> là <see cref="DateTime"/>, không khớp <see cref="DateOnly"/>).
    /// </summary>
    private sealed class FuelInventorySqlRow
    {
        public string FuelType { get; set; } = "";
        public decimal TotalStock { get; set; }
        public string StockUnit { get; set; } = "";
        public decimal? PreviousPeriodStock { get; set; }
        public decimal? ChangePercent { get; set; }
        public decimal? MinSafeStock { get; set; }
        public bool IsLowStock { get; set; }
        public int? RegionId { get; set; }
        public string? RegionName { get; set; }
        public DateTime AsOfDate { get; set; }
        public int? DaysOfStock { get; set; }
    }

    /// <summary>
    /// Hàng đọc từ <c>sp_Ai_GetFuelPriceTrend</c> — Dapper: <c>ROW_NUMBER</c> / biểu thức có thể là <see cref="long"/>,
    /// <c>DATE</c> là <see cref="DateTime"/>; không map trực tiếp <see cref="AiFuelPriceRow"/> (<see cref="DateOnly"/>, <see cref="int"/>).
    /// </summary>
    private sealed class FuelPriceTrendSqlRow
    {
        public string FuelType { get; set; } = "";
        public long PeriodIndex { get; set; }
        public string PeriodLabel { get; set; } = "";
        public DateTime EffectiveDate { get; set; }
        public decimal Price { get; set; }
        public string PriceUnit { get; set; } = "";
        public decimal? ChangeFromPrev { get; set; }
    }

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<IReadOnlyList<AiFuelInventoryRow>> GetFuelInventorySummaryAsync(
        AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);
        parameters.Add("@FromDate", request.FromDate?.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("@ToDate", request.ToDate?.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("@FuelType", request.FuelType, DbType.String, size: 100);

        var raw = await ExecuteSpAsync<FuelInventorySqlRow>(
            "dbo.sp_Ai_GetFuelInventorySummary", parameters, cancellationToken).ConfigureAwait(false);
        return raw.Select(MapFuelInventoryRow).ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<AiFuelInventoryRow>> GetRetailFuelInventorySummaryAsync(
        AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);
        parameters.Add("@FromDate", request.FromDate?.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("@ToDate", request.ToDate?.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("@FuelType", request.FuelType, DbType.String, size: 100);

        var raw = await ExecuteSpAsync<FuelInventorySqlRow>(
            "dbo.sp_Ai_GetRetailFuelInventorySummary", parameters, cancellationToken).ConfigureAwait(false);
        return raw.Select(MapFuelInventoryRow).ToList();
    }

    private static AiFuelInventoryRow MapFuelInventoryRow(FuelInventorySqlRow r) =>
        new(
            r.FuelType,
            r.TotalStock,
            r.StockUnit,
            r.PreviousPeriodStock,
            r.ChangePercent,
            r.MinSafeStock,
            r.IsLowStock,
            r.RegionId,
            r.RegionName,
            DateOnly.FromDateTime(r.AsOfDate),
            r.DaysOfStock);

    public async Task<IReadOnlyList<AiFuelPriceRow>> GetFuelPriceTrendAsync(
        AiFuelPriceRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@FuelType", request.FuelType ?? "RON95", DbType.String, size: 100);
        parameters.Add("@PeriodCount", request.PeriodCount ?? 3, DbType.Int32);

        var raw = await ExecuteSpAsync<FuelPriceTrendSqlRow>(
            "dbo.sp_Ai_GetFuelPriceTrend", parameters, cancellationToken).ConfigureAwait(false);
        return raw
            .Select(static r => new AiFuelPriceRow(
                r.FuelType,
                (int)r.PeriodIndex,
                r.PeriodLabel,
                DateOnly.FromDateTime(r.EffectiveDate),
                r.Price,
                r.PriceUnit,
                r.ChangeFromPrev))
            .ToList();
    }

    public async Task<IReadOnlyList<AiHeadOfficeRow>> GetInventoryByHeadOfficeAsync(
        AiInventoryByHeadOfficeRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);
        parameters.Add("@FuelType", request.FuelType ?? "RON95", DbType.String, size: 100);
        parameters.Add("@Top", request.Top ?? 20, DbType.Int32);

        return await ExecuteSpAsync<AiHeadOfficeRow>(
            "dbo.sp_Ai_GetInventoryByHeadOffice", parameters, cancellationToken).ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<AiStationDensityRow>> GetStationDensityByProvinceAsync(
        AiStationDensityRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);

        return await ExecuteSpAsync<AiStationDensityRow>(
            "dbo.sp_Ai_GetStationDensityByProvince", parameters, cancellationToken).ConfigureAwait(false);
    }

    public async Task LogToolCallAsync(
        AiToolLogRequest request,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            INSERT INTO dbo.AiToolLogs
                (Id, UserId, ToolName, InputJson, OutputJson, Status, ErrorMessage, DurationMs, CreatedAt)
            VALUES
                (NEWID(), @UserId, @ToolName, @InputJson, @OutputJson, @Status, @ErrorMessage, @DurationMs, SYSUTCDATETIME());
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(sql, request, cancellationToken: cancellationToken);
        await conn.ExecuteAsync(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task UpsertContextSummaryAsync(
        Guid conversationId,
        int userId,
        string summary,
        CancellationToken cancellationToken)
    {
        // MERGE atomic upsert — Phase 3 lưu vào LastAnswerSummary để Section 19.3
        // load context với summary + 5 msg gần nhất.
        const string sql =
            """
            MERGE dbo.AiConversationContexts WITH (HOLDLOCK) AS target
            USING (VALUES (@ConversationId, @UserId, @Summary)) AS src (ConversationId, UserId, Summary)
                ON target.ConversationId = src.ConversationId
            WHEN MATCHED THEN
                UPDATE SET LastAnswerSummary = src.Summary, UpdatedAt = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN
                INSERT (ConversationId, UserId, UserLoai, LastAnswerSummary)
                VALUES (src.ConversationId, src.UserId, 6, src.Summary);
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var command = new CommandDefinition(
            sql,
            new { ConversationId = conversationId, UserId = userId, Summary = summary },
            cancellationToken: cancellationToken);
        await conn.ExecuteAsync(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<SchemaCatalogEntryDto>> GetSchemaCatalogAsync(
        CancellationToken cancellationToken)
    {
        // Phase 5D — query metadata thuần, không qua SP. WHERE IsEnabled=1 vì Phase 5D
        // chỉ index entity đang bật; Phase 5G admin view sẽ dùng endpoint riêng.
        const string sql =
            """
            SELECT
                EntityCode, DisplayName, [Description], DataLayer, BaseView, [PrimaryKey],
                AllowedColumnsJson, AllowedFiltersJson, AllowedAggregatesJson,
                AllowedJoinsJson, SampleQuestionsJson,
                DefaultLimit, MaxLimit, SensitivityLevel, RequiredRoleLoai,
                Created, Modified
            FROM dbo.AiSchemaCatalog
            WHERE IsEnabled = 1
            ORDER BY EntityCode;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(sql, cancellationToken: cancellationToken);
        var raw = await conn.QueryAsync<SchemaCatalogSqlRow>(command).ConfigureAwait(false);
        return raw.Select(MapSchemaCatalogEntry).ToList();
    }

    /// <summary>
    /// Hàng raw từ <c>AiSchemaCatalog</c> — Dapper map theo tên cột. Cột JSON về dạng
    /// <see cref="string"/> để mapper deserialize bằng <see cref="System.Text.Json"/>.
    /// </summary>
    private sealed class SchemaCatalogSqlRow
    {
        public string EntityCode { get; set; } = "";
        public string DisplayName { get; set; } = "";
        public string Description { get; set; } = "";
        public string DataLayer { get; set; } = "";
        public string BaseView { get; set; } = "";
        public string PrimaryKey { get; set; } = "";
        public string AllowedColumnsJson { get; set; } = "[]";
        public string AllowedFiltersJson { get; set; } = "[]";
        public string AllowedAggregatesJson { get; set; } = "[]";
        public string? AllowedJoinsJson { get; set; }              // SQL NULL hợp lệ — phân biệt với "[]"
        public string? SampleQuestionsJson { get; set; }
        public int DefaultLimit { get; set; }
        public int MaxLimit { get; set; }
        public int SensitivityLevel { get; set; }
        public int RequiredRoleLoai { get; set; }
        public DateTime Created { get; set; }
        public DateTime? Modified { get; set; }
    }

    private SchemaCatalogEntryDto MapSchemaCatalogEntry(SchemaCatalogSqlRow r) =>
        new(
            r.EntityCode, r.DisplayName, r.Description, r.DataLayer, r.BaseView, r.PrimaryKey,
            DeserializeStringList(r.AllowedColumnsJson, r.EntityCode, nameof(r.AllowedColumnsJson)),
            DeserializeStringList(r.AllowedFiltersJson, r.EntityCode, nameof(r.AllowedFiltersJson)),
            DeserializeStringList(r.AllowedAggregatesJson, r.EntityCode, nameof(r.AllowedAggregatesJson)),
            DeserializeJoinSpecList(r.AllowedJoinsJson, r.EntityCode),
            DeserializeStringList(r.SampleQuestionsJson, r.EntityCode, nameof(r.SampleQuestionsJson)),
            r.DefaultLimit, r.MaxLimit, r.SensitivityLevel, r.RequiredRoleLoai,
            r.Created, r.Modified);

    /// <summary>JSON option dùng chung — match cả "view"/"View" trong DB.</summary>
    private static readonly JsonSerializerOptions s_schemaCatalogJsonOpts =
        new() { PropertyNameCaseInsensitive = true };

    /// <summary>
    /// Deserialize JSON array of string. NULL hoặc whitespace → empty list.
    /// Malformed JSON → log warning + empty list (KHÔNG throw để 1 entry hỏng
    /// không phá toàn bộ endpoint).
    /// </summary>
    private IReadOnlyList<string> DeserializeStringList(string? json, string entityCode, string field)
    {
        if (string.IsNullOrWhiteSpace(json)) return Array.Empty<string>();
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json, s_schemaCatalogJsonOpts)
                ?? new List<string>();
        }
        catch (JsonException ex)
        {
            logger.LogWarning(
                ex,
                "AiSchemaCatalog JSON malformed — entity={EntityCode} field={Field}. Trả empty list.",
                entityCode, field);
            return Array.Empty<string>();
        }
    }

    /// <summary>
    /// Deserialize <c>AllowedJoinsJson</c>. Phân biệt rõ:
    /// SQL NULL → <c>null</c> (entity không cấu hình joins);
    /// <c>"[]"</c> → empty list (cấu hình rỗng có chủ đích);
    /// JSON malformed → log warning + empty list (an toàn cho Phase 5E SqlBuilder).
    /// </summary>
    private IReadOnlyList<JoinSpecDto>? DeserializeJoinSpecList(string? json, string entityCode)
    {
        // null / "" / whitespace đều coi là "không cấu hình joins" (đồng nhất với SQL NULL).
        // Empty list chỉ xảy ra khi DB lưu chuỗi JSON "[]" — phân biệt rõ với null.
        if (string.IsNullOrWhiteSpace(json)) return null;
        try
        {
            return JsonSerializer.Deserialize<List<JoinSpecDto>>(json, s_schemaCatalogJsonOpts)
                ?? new List<JoinSpecDto>();
        }
        catch (JsonException ex)
        {
            logger.LogWarning(
                ex,
                "AiSchemaCatalog AllowedJoinsJson malformed — entity={EntityCode}. Trả empty list.",
                entityCode);
            return Array.Empty<JoinSpecDto>();
        }
    }

    private async Task<IReadOnlyList<T>> ExecuteSpAsync<T>(
        string spName,
        DynamicParameters parameters,
        CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            spName,
            parameters,
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        var rows = await conn.QueryAsync<T>(command).ConfigureAwait(false);
        return rows.ToList();
    }
}

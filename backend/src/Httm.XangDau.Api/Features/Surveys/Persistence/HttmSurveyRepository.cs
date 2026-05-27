using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Surveys.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Surveys.Persistence;

public sealed class HttmSurveyRepository(IConfiguration configuration) : IHttmSurveyRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<(Guid Id, string SurveyCode)> InsertAsync(
        string provinceCode,
        string? httmType,
        string createdBy,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("ProvinceCode", provinceCode);
        // SP đã normalize chuỗi rỗng → NULL; truyền null cũng OK.
        p.Add("HttmType", string.IsNullOrWhiteSpace(httmType) ? null : httmType);
        p.Add("CreatedBy", createdBy);
        p.Add("Id", dbType: DbType.Guid, direction: ParameterDirection.Output);
        p.Add("SurveyCode", dbType: DbType.String, size: 50, direction: ParameterDirection.Output);
        await conn
            .ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_Survey_Insert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        var id = p.Get<Guid>("Id");
        var code = p.Get<string>("SurveyCode") ?? string.Empty;
        return (id, code);
    }

    public async Task<HttmSurveyDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var r = await conn.QuerySingleOrDefaultAsync<SurveyDetailRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Survey_GetById",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return r is null ? null : MapDetail(r);
    }

    public async Task<HttmSurveySearchPageDto> SearchAsync(
        HttmSurveySearchQuery query,
        string? provinceScope,
        string? createdByFilter,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = (await conn
                .QueryAsync<SurveySearchRow>(
                    new CommandDefinition(
                        "dbo.sp_Httm_Survey_Search",
                        new
                        {
                            Q = query.Q,
                            Status = query.Status,
                            ProvinceCode = query.ProvinceCode,
                            ProvinceScope = provinceScope,
                            HttmType = query.HttmType,
                            CreatedBy = createdByFilter,
                            DateFrom = query.DateFrom,
                            DateTo = query.DateTo,
                            Page = query.Page,
                            PageSize = query.PageSize,
                        },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false))
            .ToList();

        if (rows.Count == 0)
            return new HttmSurveySearchPageDto { TotalCount = 0, Items = [] };

        var total = (int)rows[0].TotalCount;
        var items = rows.Select(r => new HttmSurveyListItemDto
        {
            Id = r.Id,
            SurveyCode = r.SurveyCode,
            Status = r.Status,
            ProvinceCode = r.ProvinceCode,
            HttmType = r.HttmType,
            CreatedBy = r.CreatedBy,
            CreatedAt = r.CreatedAt,
            UpdatedAt = r.UpdatedAt,
        }).ToList();

        return new HttmSurveySearchPageDto { TotalCount = total, Items = items };
    }

    public async Task<int> PatchAsync(Guid id, HttmSurveyPatchRequest patch, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var n = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    "dbo.sp_Httm_Survey_UpdatePatch",
                    new
                    {
                        Id = id,
                        patch.CurrentStep,
                        patch.Step1Data,
                        patch.Step2Data,
                        patch.Step3Data,
                        patch.Step4Data,
                        patch.Step5Data,
                        patch.Step6Data,
                        patch.Step7Data,
                        patch.ConfirmerData,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return n;
    }

    public async Task<(bool Ok, string? Err)> SubmitAsync(
        Guid id,
        string performedBy,
        CancellationToken cancellationToken = default) =>
        await ExecBoolSpAsync("dbo.sp_Httm_Survey_Submit", new { Id = id, PerformedBy = performedBy }, cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Err)> ApproveAsync(
        Guid id,
        string performedBy,
        string? notes,
        CancellationToken cancellationToken = default) =>
        await ExecBoolSpAsync(
                "dbo.sp_Httm_Survey_Approve",
                new { Id = id, PerformedBy = performedBy, Notes = notes },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Err)> RejectAsync(
        Guid id,
        string performedBy,
        string reason,
        CancellationToken cancellationToken = default) =>
        await ExecBoolSpAsync(
                "dbo.sp_Httm_Survey_Reject",
                new { Id = id, PerformedBy = performedBy, Reason = reason },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Err)> EnterReviewingAsync(
        Guid id,
        string performedBy,
        CancellationToken cancellationToken = default) =>
        await ExecBoolSpAsync(
                "dbo.sp_Httm_Survey_EnterReviewing",
                new { Id = id, PerformedBy = performedBy },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Err)> DeleteAsync(
        Guid id,
        string performedBy,
        bool forceAdmin,
        CancellationToken cancellationToken = default) =>
        await ExecBoolSpAsync(
                "dbo.sp_Httm_Survey_Delete",
                new { Id = id, PerformedBy = performedBy, ForceAdmin = forceAdmin ? 1 : 0 },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<IReadOnlyList<HttmSurveyHistoryDto>> GetHistoryAsync(
        Guid surveyId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<HistoryRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Survey_GetHistory",
                    new { SurveyId = surveyId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows
            .Select(h => new HttmSurveyHistoryDto
            {
                Id = h.Id,
                SurveyId = h.SurveyId,
                FromStatus = h.FromStatus,
                ToStatus = h.ToStatus,
                Action = h.Action,
                Notes = h.Notes,
                PerformedBy = h.PerformedBy,
                PerformedByName = string.IsNullOrWhiteSpace(h.PerformedByName) ? h.PerformedBy : h.PerformedByName,
                PerformedAt = h.PerformedAt,
            })
            .ToList();
    }

    private async Task<(bool Ok, string? Err)> ExecBoolSpAsync(
        string proc,
        object param,
        CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        var r = await conn.QuerySingleAsync<SpOk>(
                new CommandDefinition(proc, param, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return (r.Ok == 1, r.Err);
    }

    private static HttmSurveyDto MapDetail(SurveyDetailRow r) =>
        new()
        {
            Id = r.Id,
            SurveyCode = r.SurveyCode,
            Status = r.Status,
            CurrentStep = r.CurrentStep,
            Step1Data = r.Step1Data,
            Step2Data = r.Step2Data,
            Step3Data = r.Step3Data,
            Step4Data = r.Step4Data,
            Step5Data = r.Step5Data,
            Step6Data = r.Step6Data,
            Step7Data = r.Step7Data,
            ConfirmerData = r.ConfirmerData,
            ProvinceCode = r.ProvinceCode,
            HttmType = r.HttmType,
            LinkedFacilityId = r.LinkedFacilityId,
            CreatedBy = r.CreatedBy,
            SubmittedAt = r.SubmittedAt,
            ReviewedBy = r.ReviewedBy,
            ReviewedAt = r.ReviewedAt,
            CreatedAt = r.CreatedAt,
            UpdatedAt = r.UpdatedAt,
        };

    private sealed class SpOk
    {
        public int Ok { get; init; }
        public string? Err { get; init; }
    }

    private sealed class SurveySearchRow
    {
        public long TotalCount { get; init; }
        public Guid Id { get; init; }
        public string SurveyCode { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string ProvinceCode { get; init; } = string.Empty;
        public string? HttmType { get; init; }
        public string CreatedBy { get; init; } = string.Empty;
        public DateTimeOffset CreatedAt { get; init; }
        public DateTimeOffset UpdatedAt { get; init; }
    }

    private sealed class SurveyDetailRow
    {
        public Guid Id { get; init; }
        public string SurveyCode { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public short CurrentStep { get; init; }
        public string Step1Data { get; init; } = "{}";
        public string Step2Data { get; init; } = "{}";
        public string Step3Data { get; init; } = "{}";
        public string Step4Data { get; init; } = "{}";
        public string Step5Data { get; init; } = "{}";
        public string Step6Data { get; init; } = "{}";
        public string Step7Data { get; init; } = "{}";
        public string ConfirmerData { get; init; } = "{}";
        public string ProvinceCode { get; init; } = string.Empty;
        public string? HttmType { get; init; }
        public Guid? LinkedFacilityId { get; init; }
        public string CreatedBy { get; init; } = string.Empty;
        public DateTimeOffset? SubmittedAt { get; init; }
        public string? ReviewedBy { get; init; }
        public DateTimeOffset? ReviewedAt { get; init; }
        public DateTimeOffset CreatedAt { get; init; }
        public DateTimeOffset UpdatedAt { get; init; }
    }

    private sealed class HistoryRow
    {
        public Guid Id { get; init; }
        public Guid SurveyId { get; init; }
        public string? FromStatus { get; init; }
        public string ToStatus { get; init; } = string.Empty;
        public string Action { get; init; } = string.Empty;
        public string? Notes { get; init; }
        public string PerformedBy { get; init; } = string.Empty;
        public string? PerformedByName { get; init; }
        public DateTimeOffset PerformedAt { get; init; }
    }
}

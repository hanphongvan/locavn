using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Persistence;

public sealed class HttmSubmissionRepository(IConfiguration configuration) : IHttmSubmissionRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<Guid> InsertAsync(SubmissionInsertRow row, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("FacilityId", row.FacilityId);
        p.Add("SubmissionType", row.SubmissionType);
        p.Add("PayloadJson", row.PayloadJson);
        p.Add("Name", row.Name);
        p.Add("HttmType", row.HttmType);
        p.Add("ProvinceCode", row.ProvinceCode);
        p.Add("WardCode", row.WardCode);
        p.Add("SubmitterName", row.SubmitterName);
        p.Add("SubmitterPhone", row.SubmitterPhone);
        p.Add("SubmitterEmail", row.SubmitterEmail);
        p.Add("SubmitterNotes", row.SubmitterNotes);
        p.Add("SubmitterIp", row.SubmitterIp);
        p.Add("SubmitterUserAgent", row.SubmitterUserAgent);
        p.Add("Id", dbType: DbType.Guid, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_Insert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return p.Get<Guid>("Id");
    }

    public async Task<HttmSubmissionListPageDto> SearchAsync(
        string? status,
        string? provinceCode,
        string? provinceCodesCsv,
        string? submissionType,
        string? q,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = (await conn.QueryAsync<SearchRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_Search",
                    new
                    {
                        Status = status,
                        ProvinceCode = provinceCode,
                        ProvinceCodes = provinceCodesCsv,
                        SubmissionType = submissionType,
                        Q = q,
                        Page = page,
                        PageSize = pageSize,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false))
            .ToList();

        if (rows.Count == 0)
            return new HttmSubmissionListPageDto { TotalCount = 0, Items = [] };

        var total = rows[0].TotalCount;
        var items = rows.Select(r => new HttmSubmissionListItemDto
        {
            Id = r.Id,
            FacilityId = r.FacilityId,
            SubmissionType = r.SubmissionType,
            Status = r.Status,
            Name = r.Name,
            HttmType = r.HttmType,
            ProvinceCode = r.ProvinceCode,
            WardCode = r.WardCode,
            SubmitterName = r.SubmitterName,
            SubmitterPhone = r.SubmitterPhone,
            SubmitterEmail = r.SubmitterEmail,
            SubmittedAt = r.SubmittedAt,
            ReviewedBy = r.ReviewedBy,
            ReviewedAt = r.ReviewedAt,
            MergedFacilityId = r.MergedFacilityId,
        }).ToList();

        return new HttmSubmissionListPageDto { TotalCount = total, Items = items };
    }

    public async Task<SubmissionFullRow?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleOrDefaultAsync<SubmissionFullRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_GetById",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<long> CountPendingAsync(
        string? provinceCode,
        string? provinceCodesCsv,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.ExecuteScalarAsync<long>(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_CountPending",
                    new { ProvinceCode = provinceCode, ProvinceCodes = provinceCodesCsv },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<int> MarkApprovedAsync(
        Guid id,
        string reviewedBy,
        string? reviewNotes,
        Guid? mergedFacilityId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_MarkApproved",
                    new { Id = id, ReviewedBy = reviewedBy, ReviewNotes = reviewNotes, MergedFacilityId = mergedFacilityId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<int> MarkRejectedAsync(
        Guid id,
        string reviewedBy,
        string reviewNotes,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_MarkRejected",
                    new { Id = id, ReviewedBy = reviewedBy, ReviewNotes = reviewNotes },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<HttmPublicFacilityRowDto>> PublicFacilitySearchAsync(
        string? q,
        string? provinceCode,
        string? wardCode,
        int limit,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn.QueryAsync<HttmPublicFacilityRowDto>(
                new CommandDefinition(
                    "dbo.sp_Httm_Submission_PublicFacilitySearch",
                    new { Q = q, ProvinceCode = provinceCode, WardCode = wardCode, Limit = limit },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    private sealed class SearchRow
    {
        public long TotalCount { get; init; }
        public Guid Id { get; init; }
        public Guid? FacilityId { get; init; }
        public string SubmissionType { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string? HttmType { get; init; }
        public string? ProvinceCode { get; init; }
        public string? WardCode { get; init; }
        public string SubmitterName { get; init; } = string.Empty;
        public string SubmitterPhone { get; init; } = string.Empty;
        public string? SubmitterEmail { get; init; }
        public DateTimeOffset SubmittedAt { get; init; }
        public string? ReviewedBy { get; init; }
        public DateTimeOffset? ReviewedAt { get; init; }
        public Guid? MergedFacilityId { get; init; }
    }
}

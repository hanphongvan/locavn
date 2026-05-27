using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.ReportTemplates;

public interface IHttmReportTemplateRepository
{
    Task<IReadOnlyList<HttmReportTemplateDto>> ListAsync(bool onlyActive, CancellationToken cancellationToken = default);

    Task<HttmReportTemplateDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<Guid> UpsertAsync(HttmReportTemplateUpsertRequest request, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<HttmReportTemplateDueRow>> ListDueForReminderAsync(CancellationToken cancellationToken = default);

    Task TouchReminderAsync(Guid id, CancellationToken cancellationToken = default);
}

public sealed class HttmReportTemplateRepository(IConfiguration configuration) : IHttmReportTemplateRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<IReadOnlyList<HttmReportTemplateDto>> ListAsync(
        bool onlyActive,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<HttmReportTemplateDto>(
                new CommandDefinition(
                    "dbo.sp_Httm_ReportTemplate_List",
                    new { OnlyActive = onlyActive ? 1 : 0 },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<HttmReportTemplateDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleOrDefaultAsync<HttmReportTemplateDto>(
                new CommandDefinition(
                    "dbo.sp_Httm_ReportTemplate_GetById",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<Guid> UpsertAsync(HttmReportTemplateUpsertRequest request, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("Id", request.Id);
        p.Add("Code", request.Code);
        p.Add("Name", request.Name);
        p.Add("Description", request.Description);
        p.Add("ReminderIntervalDays", request.ReminderIntervalDays);
        p.Add("IsActive", request.IsActive ? 1 : 0);
        p.Add("OutId", dbType: DbType.Guid, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_ReportTemplate_Upsert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return p.Get<Guid>("OutId");
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_ReportTemplate_Delete",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<HttmReportTemplateDueRow>> ListDueForReminderAsync(
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<HttmReportTemplateDueRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_ReportTemplate_ListDueForReminder",
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task TouchReminderAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_ReportTemplate_TouchReminder",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }
}

public sealed class HttmReportTemplateDto
{
    public Guid Id { get; init; }
    public string Code { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public int ReminderIntervalDays { get; init; }
    public DateTimeOffset? LastReminderAt { get; init; }
    public bool IsActive { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }
}

public sealed class HttmReportTemplateUpsertRequest
{
    public Guid? Id { get; init; }
    public string Code { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public int ReminderIntervalDays { get; init; } = 30;
    public bool IsActive { get; init; } = true;
}

public sealed class HttmReportTemplateDueRow
{
    public Guid Id { get; init; }
    public string Code { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public int ReminderIntervalDays { get; init; }
    public DateTimeOffset? LastReminderAt { get; init; }
}

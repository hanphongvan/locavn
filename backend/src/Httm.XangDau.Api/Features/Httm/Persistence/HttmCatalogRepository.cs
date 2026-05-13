using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Httm.Persistence;

public sealed class HttmCatalogRepository(IConfiguration configuration) : IHttmCatalogRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<IReadOnlyList<HttmCatalogItemDto>> GetByTypeAsync(
        string type,
        bool activeOnly,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<CatalogRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Catalog_GetByType",
                    new { Type = type, ActiveOnly = activeOnly },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return rows
            .Select(r => new HttmCatalogItemDto
            {
                Id = r.Id,
                Type = r.Type,
                Code = r.Code,
                Name = r.Name,
                NameEn = r.NameEn,
                ParentCode = r.ParentCode,
                SortOrder = r.SortOrder,
                IsActive = r.IsActive,
                Metadata = r.Metadata,
            })
            .ToList();
    }

    private sealed class CatalogRow
    {
        public Guid Id { get; init; }
        public string Type { get; init; } = string.Empty;
        public string Code { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string? NameEn { get; init; }
        public string? ParentCode { get; init; }
        public short SortOrder { get; init; }
        public bool IsActive { get; init; }
        public string? Metadata { get; init; }
    }
}

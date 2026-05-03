using System.Data;
using System.Data.Common;
using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Contracts;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Persistence;

public sealed class StoreAdminInventoryCurrentQuery(DmpPortalDbContext db) : IStoreAdminInventoryCurrentQuery
{
    private const string ProcPaged = "dbo.sp_StoreAdmin_InventoryCurrent_ListPaged";
    private const string ProcByStore = "dbo.sp_StoreAdmin_InventoryCurrent_ListByStore";

    public async Task<(IReadOnlyList<StoreAdminInventoryCurrentLineDto> Items, int TotalCount)> ListCurrentAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default)
    {
        await db.Database.OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var connection = db.Database.GetDbConnection();
            await using var cmd = connection.CreateCommand();
            if (db.Database.CurrentTransaction is IInfrastructure<DbTransaction> infra)
                cmd.Transaction = infra.Instance;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = ProcPaged;

            AddInt32(cmd, "@Skip", skip);
            AddInt32(cmd, "@Take", take);
            AddNullableInt32(cmd, "@DonViId", donViId);
            AddNullableInt32(cmd, "@ProductId", productId);
            if (donViScopeIds is { Count: > 0 })
                AddString(cmd, "@DonViScopeCsv", string.Join(',', donViScopeIds));
            else
                AddDbNull(cmd, "@DonViScopeCsv");

            AddInt32(cmd, "@RetailCapDonViId", PetrolRetailConstants.CapDonViId);

            var totalOut = cmd.CreateParameter();
            totalOut.ParameterName = "@TotalCount";
            totalOut.DbType = DbType.Int32;
            totalOut.Direction = ParameterDirection.Output;
            cmd.Parameters.Add(totalOut);

            var items = new List<StoreAdminInventoryCurrentLineDto>();
            await using (var reader = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false))
            {
                while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
                    items.Add(ReadLine(reader));
            }

            var total = totalOut.Value is DBNull or null ? 0 : Convert.ToInt32(totalOut.Value);
            return (items, total);
        }
        finally
        {
            await db.Database.CloseConnectionAsync().ConfigureAwait(false);
        }
    }

    public async Task<IReadOnlyList<StoreAdminInventoryCurrentLineDto>> ListCurrentByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        await db.Database.OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var connection = db.Database.GetDbConnection();
            await using var cmd = connection.CreateCommand();
            if (db.Database.CurrentTransaction is IInfrastructure<DbTransaction> infra)
                cmd.Transaction = infra.Instance;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = ProcByStore;

            AddInt32(cmd, "@DonViId", donViId);
            AddInt32(cmd, "@RetailCapDonViId", PetrolRetailConstants.CapDonViId);

            var items = new List<StoreAdminInventoryCurrentLineDto>();
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
                items.Add(ReadLine(reader));

            return items;
        }
        finally
        {
            await db.Database.CloseConnectionAsync().ConfigureAwait(false);
        }
    }

    private static void AddInt32(DbCommand cmd, string name, int value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.DbType = DbType.Int32;
        p.Value = value;
        cmd.Parameters.Add(p);
    }

    private static void AddNullableInt32(DbCommand cmd, string name, int? value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.DbType = DbType.Int32;
        p.Value = value ?? (object)DBNull.Value;
        cmd.Parameters.Add(p);
    }

    private static void AddString(DbCommand cmd, string name, string value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.DbType = DbType.String;
        p.Value = value;
        cmd.Parameters.Add(p);
    }

    private static void AddDbNull(DbCommand cmd, string name)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.DbType = DbType.String;
        p.Value = DBNull.Value;
        cmd.Parameters.Add(p);
    }

    private static StoreAdminInventoryCurrentLineDto ReadLine(DbDataReader r)
    {
        var donViId = r.GetInt32(r.GetOrdinal("DonViId"));
        var productId = r.GetInt32(r.GetOrdinal("ProductId"));
        var currentQty = r.GetDecimal(r.GetOrdinal("CurrentQuantity"));
        var productCode = r.GetString(r.GetOrdinal("ProductCode"));
        var productName = r.GetString(r.GetOrdinal("ProductName"));

        var unitIdOrd = r.GetOrdinal("UnitId");
        int? unitId = r.IsDBNull(unitIdOrd) ? null : r.GetInt32(unitIdOrd);

        var unitMaOrd = r.GetOrdinal("UnitMa");
        string? unitMa = r.IsDBNull(unitMaOrd) ? null : r.GetString(unitMaOrd);

        var unitTenOrd = r.GetOrdinal("UnitTen");
        string? unitTen = r.IsDBNull(unitTenOrd) ? null : r.GetString(unitTenOrd);

        var lastTx = r.GetDateTime(r.GetOrdinal("LastTransactionDate"));

        return new StoreAdminInventoryCurrentLineDto(
            donViId,
            productId,
            currentQty,
            productCode,
            productName,
            unitId,
            unitMa,
            unitTen,
            lastTx);
    }
}

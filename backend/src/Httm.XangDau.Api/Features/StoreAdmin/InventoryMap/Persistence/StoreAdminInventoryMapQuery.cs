using System.Data;
using System.Data.Common;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Persistence;

public sealed class StoreAdminInventoryMapQuery(DmpPortalDbContext db) : IStoreAdminInventoryMapQuery
{
    private const string Proc = "dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode";

    public async Task<IReadOnlyList<StoreAdminInventoryMapStationDto>> ListByGroupCodeAsync(
        string groupCode,
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
            cmd.CommandText = Proc;

            AddString(cmd, "@GroupCode", groupCode);

            var items = new List<StoreAdminInventoryMapStationDto>();
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
                items.Add(ReadRow(reader));

            return items;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            // Client disconnected before query completed - return empty result
            return [];
        }
        finally
        {
            await db.Database.CloseConnectionAsync().ConfigureAwait(false);
        }
    }

    private static void AddString(DbCommand cmd, string name, string value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.DbType = DbType.String;
        p.Value = value;
        cmd.Parameters.Add(p);
    }

    private static StoreAdminInventoryMapStationDto ReadRow(DbDataReader r)
    {
        var stationId = r.GetInt32(r.GetOrdinal("StationId"));
        var stationCode = r.GetString(r.GetOrdinal("StationCode"));
        var stationName = r.GetString(r.GetOrdinal("StationName"));

        var addrOrd = r.GetOrdinal("Address");
        string? address = r.IsDBNull(addrOrd) ? null : r.GetString(addrOrd);

        var latOrd = r.GetOrdinal("Latitude");
        double? latitude = r.IsDBNull(latOrd) ? null : r.GetDouble(latOrd);

        var lngOrd = r.GetOrdinal("Longitude");
        double? longitude = r.IsDBNull(lngOrd) ? null : r.GetDouble(lngOrd);

        var qty = r.GetDecimal(r.GetOrdinal("CurrentQuantity"));
        var stockStatus = r.GetString(r.GetOrdinal("StockStatus"));

        return new StoreAdminInventoryMapStationDto(
            stationId,
            stationCode,
            stationName,
            address,
            latitude,
            longitude,
            qty,
            stockStatus);
    }
}

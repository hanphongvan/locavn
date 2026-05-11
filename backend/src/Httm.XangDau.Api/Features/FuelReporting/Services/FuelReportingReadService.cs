using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.FuelReporting;
using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.FuelReporting.Persistence;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Reporting;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.FuelReporting.Services;

public sealed class FuelReportingReadService(
    DmpPortalDbContext db,
    IThongKePeriodResolver periods,
    IStationRetailPriceDataAccess retailBoardPrices,
    IFuelReportingInventorySummaryDataAccess inventorySummary) : IFuelReportingReadService
{
    private const int SnapshotPriceLineCap = 50;
    private const int SnapshotStockLineCap = 40;
    private const int LatestPricesSqlCommandTimeoutSeconds = 120;

    public async Task<(LatestFuelPricesResponseDto Data, string? Error)> GetLatestPricesAsync(
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default)
    {
        var err = await ValidateKieuKyAsync(kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return (new LatestFuelPricesResponseDto(null, Array.Empty<FuelPriceLineDto>()), err);

        var meta = await periods.ResolveLatestWithMetadataAsync(kieuKyBaoCao, cancellationToken);
        if (meta is null)
            return (new LatestFuelPricesResponseDto(null, Array.Empty<FuelPriceLineDto>()), null);

        var key = ToKey(meta);
        // ROW_NUMBER per station matches GetPricesByStationAsync (ThoiGianGui desc, Id desc).
        // EF GroupBy + join often produced a slow plan on large QT_TK_ThongKe; one parameterized batch is cheaper.
        var items = await QueryLatestFuelPriceLinesSqlAsync(key, cancellationToken).ConfigureAwait(false);

        return (new LatestFuelPricesResponseDto(meta, items), null);
    }

    public async Task<(StationFuelPricesResponseDto? Data, string? Error)> GetPricesByStationAsync(
        int stationId,
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "stationId must be a positive integer.");

        var err = await ValidateKieuKyAsync(kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return (null, err);

        if (!await IsPetrolStationAsync(stationId, cancellationToken))
            return (null, null);

        var meta = await periods.ResolveLatestWithMetadataAsync(kieuKyBaoCao, cancellationToken);
        if (meta is null)
        {
            var name = await StationNameAsync(stationId, cancellationToken);
            return (new StationFuelPricesResponseDto(null, stationId, name, Array.Empty<FuelPriceLineDto>()), null);
        }

        var periodDto = meta;
        var key = ToKey(meta);
        var tkId = await db.QtTkThongKes.AsNoTracking()
            .WhereSamePeriod(key)
            .Where(t => t.DonViCap1 == stationId)
            .OrderByDescending(t => t.ThoiGianGui)
            .ThenByDescending(t => t.Id)
            .Select(t => t.Id)
            .FirstOrDefaultAsync(cancellationToken);

        var stationName = await StationNameAsync(stationId, cancellationToken);
        if (tkId == Guid.Empty)
            return (new StationFuelPricesResponseDto(periodDto, stationId, stationName, Array.Empty<FuelPriceLineDto>()), null);

        var lines = await (
            from l in db.QtTkThongKeChiTiets.AsNoTracking()
            where l.ThongKeId == tkId
            where l.LoaiGia != null || l.ThoiDiemDinhGia != null
            where l.Xoa == null || l.Xoa == 0
            orderby l.ThuTu, l.MaSo
            select new FuelPriceLineDto(
                stationId,
                stationName,
                tkId,
                l.Id,
                l.MaSo,
                l.TenThongKe,
                l.LoaiGia,
                l.ThoiDiemDinhGia,
                l.So_01,
                l.So_02,
                l.So_03)
        ).ToListAsync(cancellationToken);

        return (new StationFuelPricesResponseDto(periodDto, stationId, stationName, lines), null);
    }

    public async Task<(InventorySummaryResponseDto Data, string? Error)> GetInventorySummaryAsync(
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default)
    {
        if (kieuKyBaoCao is { } kf && !await inventorySummary.KieuKyBaoCaoExistsAsync(kf, cancellationToken).ConfigureAwait(false))
        {
            return (
                new InventorySummaryResponseDto(
                    null,
                    0,
                    0,
                    null,
                    Array.Empty<InventoryNhomGroupDto>()),
                $"kieuKyBaoCao {kieuKyBaoCao} does not exist in DM_KieuKyBaoCao.");
        }

        var data = await inventorySummary
            .GetInventorySummaryAsync(kieuKyBaoCao, cancellationToken)
            .ConfigureAwait(false);
        return (data, null);
    }

    public async Task<(StationInventoryResponseDto? Data, string? Error)> GetInventoryByStationAsync(
        int stationId,
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "stationId must be a positive integer.");

        var err = await ValidateKieuKyAsync(kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return (null, err);

        if (!await IsPetrolStationAsync(stationId, cancellationToken))
            return (null, null);

        var meta = await periods.ResolveLatestWithMetadataAsync(kieuKyBaoCao, cancellationToken);
        if (meta is null)
        {
            var name = await StationNameAsync(stationId, cancellationToken);
            return (new StationInventoryResponseDto(null, stationId, name, Array.Empty<FuelStockLineDto>()), null);
        }

        var periodDto = meta;
        var key = ToKey(meta);
        var tkId = await db.QtTkThongKes.AsNoTracking()
            .WhereSamePeriod(key)
            .Where(t => t.DonViCap1 == stationId)
            .OrderByDescending(t => t.ThoiGianGui)
            .ThenByDescending(t => t.Id)
            .Select(t => t.Id)
            .FirstOrDefaultAsync(cancellationToken);

        var stationName = await StationNameAsync(stationId, cancellationToken);
        if (tkId == Guid.Empty)
            return (new StationInventoryResponseDto(periodDto, stationId, stationName, Array.Empty<FuelStockLineDto>()), null);

        var items = await (
            from l in db.QtTkThongKeChiTiets.AsNoTracking()
            where l.ThongKeId == tkId
            where l.LoaiGia == null && l.ThoiDiemDinhGia == null
            where l.So_01 != null || l.So_02 != null || l.So_03 != null
            where l.Xoa == null || l.Xoa == 0
            orderby l.ThuTu, l.MaSo
            select new FuelStockLineDto(l.Id, l.MaSo, l.TenThongKe, l.Nhom, l.So_01, l.So_02, l.So_03)
        ).ToListAsync(cancellationToken);

        return (new StationInventoryResponseDto(periodDto, stationId, stationName, items), null);
    }

    public async Task<(StationReportingPricesDto? Prices, StationReportingStockDto? Stock)> GetReportingSnapshotsForStationAsync(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        if (!await IsPetrolStationAsync(stationId, cancellationToken))
            return (null, null);

        var meta = await periods.ResolveLatestWithMetadataAsync(null, cancellationToken);
        if (meta is null)
            return (null, null);

        var periodDto = meta;
        var key = ToKey(meta);
        var tkId = await db.QtTkThongKes.AsNoTracking()
            .WhereSamePeriod(key)
            .Where(t => t.DonViCap1 == stationId)
            .OrderByDescending(t => t.ThoiGianGui)
            .ThenByDescending(t => t.Id)
            .Select(t => t.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (tkId == Guid.Empty)
        {
            return (
                new StationReportingPricesDto(periodDto, Array.Empty<FuelPriceLineDto>()),
                new StationReportingStockDto(periodDto, 0, null, Array.Empty<FuelStockLineDto>()));
        }

        var stationName = await StationNameAsync(stationId, cancellationToken);

        var priceLines = await (
            from l in db.QtTkThongKeChiTiets.AsNoTracking()
            where l.ThongKeId == tkId
            where l.LoaiGia != null || l.ThoiDiemDinhGia != null
            where l.Xoa == null || l.Xoa == 0
            orderby l.ThuTu, l.MaSo
            select new FuelPriceLineDto(
                stationId,
                stationName,
                tkId,
                l.Id,
                l.MaSo,
                l.TenThongKe,
                l.LoaiGia,
                l.ThoiDiemDinhGia,
                l.So_01,
                l.So_02,
                l.So_03)
        ).Take(SnapshotPriceLineCap).ToListAsync(cancellationToken);

        var stockLines = await (
            from l in db.QtTkThongKeChiTiets.AsNoTracking()
            where l.ThongKeId == tkId
            where l.LoaiGia == null && l.ThoiDiemDinhGia == null
            where l.So_01 != null || l.So_02 != null || l.So_03 != null
            where l.Xoa == null || l.Xoa == 0
            orderby l.ThuTu, l.MaSo
            select new FuelStockLineDto(l.Id, l.MaSo, l.TenThongKe, l.Nhom, l.So_01, l.So_02, l.So_03)
        ).Take(SnapshotStockLineCap).ToListAsync(cancellationToken);

        var totalStockSo01 = await db.QtTkThongKeChiTiets.AsNoTracking()
            .Where(l => l.ThongKeId == tkId)
            .Where(l => l.LoaiGia == null && l.ThoiDiemDinhGia == null)
            .Where(l => l.So_01 != null || l.So_02 != null || l.So_03 != null)
            .Where(l => l.Xoa == null || l.Xoa == 0)
            .SumAsync(l => (decimal?)l.So_01, cancellationToken);

        var stockCount = await db.QtTkThongKeChiTiets.AsNoTracking()
            .Where(l => l.ThongKeId == tkId)
            .Where(l => l.LoaiGia == null && l.ThoiDiemDinhGia == null)
            .Where(l => l.So_01 != null || l.So_02 != null || l.So_03 != null)
            .Where(l => l.Xoa == null || l.Xoa == 0)
            .CountAsync(cancellationToken);

        return (
            new StationReportingPricesDto(periodDto, priceLines),
            new StationReportingStockDto(periodDto, stockCount, totalStockSo01, stockLines));
    }

    /// <inheritdoc />
    public async Task<IReadOnlyDictionary<int, MapStationPrices>> GetMapPriceSnapshotsForStationsAsync(
        IReadOnlyList<int> stationIds,
        CancellationToken cancellationToken = default)
    {
        var distinct = stationIds.Distinct().ToList();
        var result = distinct.ToDictionary(id => id, _ => new MapStationPrices(null, null));
        if (distinct.Count == 0)
            return result;

        var rows = await retailBoardPrices
            .GetMapBoardPricesByDonViIdsAsync(distinct, PetrolRetailConstants.CapDonViId, cancellationToken)
            .ConfigureAwait(false);

        foreach (var row in rows)
        {
            if (!result.ContainsKey(row.DonViId))
                continue;
            var cur = result[row.DonViId];
            decimal? ron = cur.PriceRon95;
            decimal? die = cur.PriceDiesel;
            if (string.Equals(row.ProductCode, "RON95", StringComparison.OrdinalIgnoreCase))
                ron = row.Price;
            else if (string.Equals(row.ProductCode, "DIESEL", StringComparison.OrdinalIgnoreCase))
                die = row.Price;
            result[row.DonViId] = new MapStationPrices(ron, die);
        }

        return result;
    }

    private static ThongKePeriodKey ToKey(ReportingPeriodDto m) =>
        new(m.KieuKyBaoCaoId, m.TuNgay, m.DenNgay);

    private async Task<IReadOnlyList<FuelPriceLineDto>> QueryLatestFuelPriceLinesSqlAsync(
        ThongKePeriodKey key,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            WITH RankedTk AS (
                SELECT
                    tk.[Id],
                    tk.[don_vi_cap1],
                    ROW_NUMBER() OVER (PARTITION BY tk.[don_vi_cap1] ORDER BY tk.[ThoiGianGui] DESC, tk.[Id] DESC) AS rn
                FROM [QT_TK_ThongKe] AS tk
                WHERE tk.[Loai] = 1
                  AND tk.[don_vi_cap1] IS NOT NULL
                  AND tk.[DenNgay] = @DenNgay
                  AND ((@HasKieuKy = 0 AND tk.[KieuKyBaoCao] IS NULL) OR (@HasKieuKy = 1 AND tk.[KieuKyBaoCao] = @KieuKyBaoCao))
                  AND ((@HasTuNgay = 0 AND tk.[TuNgay] IS NULL) OR (@HasTuNgay = 1 AND tk.[TuNgay] = @TuNgay))
            )
            SELECT
                rt.[don_vi_cap1] AS StationId,
                d.[Ten] AS StationName,
                rt.[Id] AS ThongKeId,
                l.[Id] AS LineId,
                l.[MaSo],
                l.[TenThongKe],
                l.[LoaiGia],
                l.[ThoiDiemDinhGia],
                l.[So_01] AS So01,
                l.[So_02] AS So02,
                l.[So_03] AS So03
            FROM RankedTk AS rt
            INNER JOIN [QT_TK_ThongKeChiTiet] AS l ON l.[ThongKeId] = rt.[Id]
            LEFT JOIN [DM_DonVi] AS d ON d.[Id] = rt.[don_vi_cap1]
            WHERE rt.[rn] = 1
              AND (l.[LoaiGia] IS NOT NULL OR l.[ThoiDiemDinhGia] IS NOT NULL)
              AND (l.[Xoa] IS NULL OR l.[Xoa] = 0)
            ORDER BY rt.[don_vi_cap1], l.[ThuTu], l.[MaSo];
            """;

        var hasKieuKy = key.KieuKyBaoCao is not null ? 1 : 0;
        var hasTuNgay = key.TuNgay is not null ? 1 : 0;
        var parameters = new DynamicParameters();
        parameters.Add("DenNgay", key.DenNgay.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("HasKieuKy", hasKieuKy, DbType.Int32);
        parameters.Add("KieuKyBaoCao", key.KieuKyBaoCao ?? 0, DbType.Int32);
        parameters.Add("HasTuNgay", hasTuNgay, DbType.Int32);
        parameters.Add("TuNgay", key.TuNgay?.ToDateTime(TimeOnly.MinValue), DbType.Date);

        await db.Database.OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var connection = db.Database.GetDbConnection();
            var rows = await connection
                .QueryAsync<LatestPriceLineSqlRow>(
                    new CommandDefinition(
                        sql,
                        parameters,
                        commandTimeout: LatestPricesSqlCommandTimeoutSeconds,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            return rows
                .Select(r => new FuelPriceLineDto(
                    r.StationId,
                    r.StationName,
                    r.ThongKeId,
                    r.LineId,
                    r.MaSo,
                    r.TenThongKe,
                    r.LoaiGia,
                    r.ThoiDiemDinhGia,
                    r.So01,
                    r.So02,
                    r.So03))
                .ToList();
        }
        finally
        {
            await db.Database.CloseConnectionAsync().ConfigureAwait(false);
        }
    }

    private async Task<string?> ValidateKieuKyAsync(int? kieuKyBaoCao, CancellationToken cancellationToken)
    {
        if (kieuKyBaoCao is null)
            return null;
        if (!await db.DmKieuKyBaoCaos.AsNoTracking().AnyAsync(k => k.Id == kieuKyBaoCao.Value, cancellationToken))
            return $"kieuKyBaoCao {kieuKyBaoCao} does not exist in DM_KieuKyBaoCao.";
        return null;
    }

    private Task<bool> IsPetrolStationAsync(int stationId, CancellationToken cancellationToken) =>
        db.DmDonVis.AsNoTracking()
            .AnyAsync(d => d.Id == stationId && d.CapDonViId == PetrolRetailConstants.CapDonViId, cancellationToken);

    private Task<string?> StationNameAsync(int stationId, CancellationToken cancellationToken) =>
        db.DmDonVis.AsNoTracking()
            .Where(d => d.Id == stationId)
            .Select(d => d.Ten)
            .FirstOrDefaultAsync(cancellationToken);

    private sealed class LatestPriceLineSqlRow
    {
        public int StationId { get; init; }
        public string? StationName { get; init; }
        public Guid ThongKeId { get; init; }
        public Guid LineId { get; init; }
        public string? MaSo { get; init; }
        public string? TenThongKe { get; init; }
        public int? LoaiGia { get; init; }
        public DateTime? ThoiDiemDinhGia { get; init; }
        public decimal? So01 { get; init; }
        public decimal? So02 { get; init; }
        public decimal? So03 { get; init; }
    }
}

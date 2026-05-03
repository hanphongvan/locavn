using System;
using System.Globalization;
using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.FuelReporting.Services;
using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Features.Stations.Persistence;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>
/// Read-only petrol station APIs. <c>DM_DonVi</c> with <c>CapDonViId = 248</c>; optional <c>StationOperatingHours</c> for visitor open/closed.
/// </summary>
public sealed class StationReadService(
    DmpPortalDbContext db,
    IFuelReportingReadService fuelReporting,
    IStationListSearchDataAccess stationListSearch,
    IStationMapMarkersDataAccess stationMapMarkers) : IStationReadService
{
    public async Task<(PagedStationsResponse<StationListItemDto> Data, string? Error)> ListAsync(
        int skip,
        int take,
        string? keyword,
        string? provinceCode,
        string? districtCode,
        string? status,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StationReadValidator.DefaultTake;

        var (_, dow, nowTime) = StationVietnamClock.NowParts(DateTime.UtcNow);
        var dowByte = (byte)dow;

        var err = StationReadValidator.ValidatePagination(skip, take)
                  ?? StationReadValidator.ValidateStatus(status);
        if (err is not null)
            return (EmptyPage<StationListItemDto>(skip, take), err);

        int? districtQuanHuyenId = null;
        if (!string.IsNullOrWhiteSpace(districtCode))
        {
            if (!StationReadValidator.TryParseDistrictCode(districtCode, out var qhid, out var dErr))
                return (EmptyPage<StationListItemDto>(skip, take), dErr);
            districtQuanHuyenId = qhid;
        }

        var provinceTrim = string.IsNullOrWhiteSpace(provinceCode) ? null : provinceCode.Trim();
        var provErr = await ValidateProvinceMaExistsAsync(provinceTrim, cancellationToken);
        if (provErr is not null)
            return (EmptyPage<StationListItemDto>(skip, take), provErr);

        var kw = string.IsNullOrWhiteSpace(keyword) ? null : keyword.Trim();
        if (kw is { Length: > StationReadValidator.MaxKeywordLength })
            return (EmptyPage<StationListItemDto>(skip, take), $"keyword max length is {StationReadValidator.MaxKeywordLength}.");

        var (totalLong, searchRows) = await stationListSearch.SearchAsync(
                skip,
                take,
                kw,
                provinceTrim,
                districtQuanHuyenId,
                status,
                dowByte,
                nowTime,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);

        var total = totalLong > int.MaxValue ? int.MaxValue : (int)totalLong;
        var pageRows = searchRows
            .Select(r => new StationListPageRow(
                r.StationId,
                r.StationCode,
                r.StationName,
                r.AddressLine,
                r.ProvinceCode,
                r.ProvinceName,
                r.WardCode,
                r.WardName,
                r.DistrictId,
                r.LicenseNumber,
                r.IsActive,
                ToTimeOnly(r.OpenTime),
                ToTimeOnly(r.CloseTime)))
            .ToList();

        var ids = pageRows.Select(r => r.StationId).ToList();
        var hours = await db.StationOperatingHours.AsNoTracking()
            .Where(h => ids.Contains(h.DonViId))
            .ToListAsync(cancellationToken);
        var hoursByStation = hours.ToLookup(h => h.DonViId);
        var openMap = StationOperationalEvaluator.BuildOpenNowMap(ids, hours, dow, nowTime);
        var priceMap = await fuelReporting.GetMapPriceSnapshotsForStationsAsync(ids, cancellationToken);

        var items = pageRows.Select(r =>
        {
            var todayH = hoursByStation[r.StationId].Where(h => h.DayOfWeek == dowByte).ToList();
            var openNowWeekly = openMap.TryGetValue(r.StationId, out var on) ? on : null;
            var openNow = r.OpenTime is not null && r.CloseTime is not null
                ? StationOperationalEvaluator.IsOpenNowFromDonViTimes(r.OpenTime, r.CloseTime, nowTime)
                : openNowWeekly;
            var (op, cl) = StationOperationalEvaluator.ResolveDisplayHours(r.OpenTime, r.CloseTime, todayH);
            priceMap.TryGetValue(r.StationId, out var px);
            px ??= new MapStationPrices(null, null);
            return new StationListItemDto(
                r.StationId,
                r.StationCode,
                r.StationName,
                r.AddressLine,
                r.ProvinceCode,
                r.ProvinceName,
                r.WardCode,
                r.WardName,
                r.DistrictId,
                r.LicenseNumber,
                r.IsActive,
                openNow,
                StationOperationalEvaluator.ToOpenStatus(openNow),
                op,
                cl,
                px.PriceRon95,
                px.PriceDiesel);
        }).ToList();

        return (new PagedStationsResponse<StationListItemDto>(items, total, skip, take), null);
    }

    public async Task<(PagedStationsResponse<StationMapItemDto> Data, string? Error)> MapAsync(
        int skip,
        int take,
        string? provinceCode,
        string? districtCode,
        string? status,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StationReadValidator.DefaultTake;

        var (_, dow, nowTime) = StationVietnamClock.NowParts(DateTime.UtcNow);
        var dowByte = (byte)dow;

        var err = StationReadValidator.ValidatePagination(skip, take)
                  ?? StationReadValidator.ValidateStatus(status);
        if (err is not null)
            return (EmptyPage<StationMapItemDto>(skip, take), err);

        int? districtQuanHuyenId = null;
        if (!string.IsNullOrWhiteSpace(districtCode))
        {
            if (!StationReadValidator.TryParseDistrictCode(districtCode, out var qhid, out var dErr))
                return (EmptyPage<StationMapItemDto>(skip, take), dErr);
            districtQuanHuyenId = qhid;
        }

        var provinceTrim = string.IsNullOrWhiteSpace(provinceCode) ? null : provinceCode.Trim();
        var provErr = await ValidateProvinceMaExistsAsync(provinceTrim, cancellationToken);
        if (provErr is not null)
            return (EmptyPage<StationMapItemDto>(skip, take), provErr);

        var (totalLong, sqlRows) = await stationMapMarkers
            .ListPagedAsync(
                skip,
                take,
                provinceTrim,
                districtQuanHuyenId,
                status,
                dowByte,
                nowTime,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);

        var total = totalLong > int.MaxValue ? int.MaxValue : (int)totalLong;
        var merged = await BuildMapStationItemsAsync(sqlRows, dow, dowByte, nowTime, cancellationToken)
            .ConfigureAwait(false);

        return (new PagedStationsResponse<StationMapItemDto>(merged, total, skip, take), null);
    }

    /// <inheritdoc />
    public async Task<(PagedStationsResponse<StationMapItemDto> Data, string? Error)> MapByBoundsAsync(
        int skip,
        int take,
        double minLat,
        double maxLat,
        double minLng,
        double maxLng,
        string? status,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StationReadValidator.DefaultTake;

        var (_, dow, nowTime) = StationVietnamClock.NowParts(DateTime.UtcNow);
        var dowByte = (byte)dow;

        var err = StationReadValidator.ValidatePagination(skip, take)
                  ?? StationReadValidator.ValidateStatus(status)
                  ?? StationReadValidator.ValidateMapBounds(minLat, maxLat, minLng, maxLng);
        if (err is not null)
            return (EmptyPage<StationMapItemDto>(skip, take), err);

        var (totalLong, sqlRows) = await stationMapMarkers
            .ListByBoundsAsync(
                skip,
                take,
                minLat,
                maxLat,
                minLng,
                maxLng,
                status,
                dowByte,
                nowTime,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);

        var total = totalLong > int.MaxValue ? int.MaxValue : (int)totalLong;
        var merged = await BuildMapStationItemsAsync(sqlRows, dow, dowByte, nowTime, cancellationToken)
            .ConfigureAwait(false);

        return (new PagedStationsResponse<StationMapItemDto>(merged, total, skip, take), null);
    }

    public async Task<(StationDetailDto? Data, string? Error)> GetDetailAsync(int id, CancellationToken cancellationToken = default)
    {
        if (id <= 0)
            return (null, "id must be a positive integer.");

        var (_, dow, nowTime) = StationVietnamClock.NowParts(DateTime.UtcNow);
        var dowByte = (byte)dow;

        var row = await (
            from d in db.DmDonVis.AsNoTracking()
            where d.Id == id && d.CapDonViId == PetrolRetailConstants.CapDonViId
            join t in db.DmTinhs.AsNoTracking() on d.Tinh equals t.Id into tg
            from t in tg.DefaultIfEmpty()
            join x in db.DmXaPhuongs.AsNoTracking() on d.Xa equals x.Id into xg
            from x in xg.DefaultIfEmpty()
            select new { d, t, x }
        ).FirstOrDefaultAsync(cancellationToken);

        if (row is null)
            return (null, null);

        double? lat = null;
        double? lng = null;
        if (StationCoordinateRules.TryToDisplayCoordinates(row.d.ViDo, row.d.KinhDo, out var la, out var ln))
        {
            lat = la;
            lng = ln;
        }

        var (repPrices, repStock) = await fuelReporting.GetReportingSnapshotsForStationAsync(id, cancellationToken);
        var priceMap = await fuelReporting.GetMapPriceSnapshotsForStationsAsync(new[] { id }, cancellationToken);
        priceMap.TryGetValue(id, out var mapPx);
        mapPx ??= new MapStationPrices(null, null);
        var qh = row.x?.QuanHuyenId;
        var districtCode = qh is { } qid ? qid.ToString(CultureInfo.InvariantCulture) : null;

        var hours = await db.StationOperatingHours.AsNoTracking()
            .Where(h => h.DonViId == id)
            .OrderBy(h => h.DayOfWeek)
            .ToListAsync(cancellationToken);

        var todayH = hours.Where(h => h.DayOfWeek == dowByte).ToList();
        var openNow = row.d.OpenTime is not null && row.d.CloseTime is not null
            ? StationOperationalEvaluator.IsOpenNowFromDonViTimes(row.d.OpenTime, row.d.CloseTime, nowTime)
            : StationOperationalEvaluator.IsOpenNow(todayH, nowTime);
        var (op, cl) = StationOperationalEvaluator.ResolveDisplayHours(row.d.OpenTime, row.d.CloseTime, todayH);
        var weekly = hours
            .Select(h => new StationOperatingSlotDto(
                h.DayOfWeek,
                h.IsClosedAllDay,
                h.OpensAt?.ToString("HH:mm"),
                h.ClosesAt?.ToString("HH:mm")))
            .ToList();

        var storeServiceRows = await db.StationStoreServices.AsNoTracking()
            .Where(s => s.DonViId == id)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.DisplayName)
            .Select(s => new StationDetailStoreServiceDto(
                s.ServiceCode,
                s.DisplayName,
                s.IconKey,
                s.IsActive,
                s.Price,
                s.SortOrder))
            .ToListAsync(cancellationToken);

        var dto = new StationDetailDto(
            row.d.Id,
            row.d.Ma,
            row.d.Ten,
            row.d.DienThoai,
            row.d.Email,
            row.d.DiaChiChiTiet ?? row.d.DiaChi,
            row.d.SoGiayPhep,
            row.d.NgayCap,
            row.d.NgayHetHan,
            lat,
            lng,
            row.t?.Ma,
            row.t?.Ten,
            row.x?.Ma,
            row.x?.Ten,
            qh,
            districtCode,
            row.d.TrangThai,
            openNow,
            StationOperationalEvaluator.ToOpenStatus(openNow),
            op,
            cl,
            weekly.Count == 0 ? null : weekly,
            repPrices,
            repStock,
            mapPx.PriceRon95,
            mapPx.PriceDiesel,
            storeServiceRows.Count == 0 ? null : storeServiceRows);

        return (dto, null);
    }

    private static TimeOnly? ToTimeOnly(TimeSpan? value) =>
        value is null ? null : TimeOnly.FromTimeSpan(value.Value);

    private static PagedStationsResponse<T> EmptyPage<T>(int skip, int take) =>
        new(Array.Empty<T>(), 0, skip, take);

    private async Task<List<StationMapItemDto>> BuildMapStationItemsAsync(
        IReadOnlyList<StationMapMarkersSqlRow> sqlRows,
        DayOfWeek dow,
        byte dowByte,
        TimeOnly nowTime,
        CancellationToken cancellationToken)
    {
        var mapRows = sqlRows
            .Select(r => new StationMapPageRow(
                r.StationId,
                r.StationName,
                r.Latitude,
                r.Longitude,
                r.ShortAddress,
                r.TrangThai,
                r.OpenTime is { } ot ? TimeOnly.FromTimeSpan(ot) : null,
                r.CloseTime is { } ct ? TimeOnly.FromTimeSpan(ct) : null))
            .ToList();

        var ids = mapRows.Select(r => r.StationId).ToList();
        var activeServiceRows = await db.StationStoreServices.AsNoTracking()
            .Where(s => ids.Contains(s.DonViId) && s.IsActive)
            .Select(s => new { s.DonViId, s.ServiceCode })
            .ToListAsync(cancellationToken);
        var activeCodesByStation = activeServiceRows
            .GroupBy(x => x.DonViId)
            .ToDictionary(
                g => g.Key,
                g => (IReadOnlyList<string>)g
                    .Select(x => x.ServiceCode)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .OrderBy(x => x, StringComparer.OrdinalIgnoreCase)
                    .ToList());

        var hours = await db.StationOperatingHours.AsNoTracking()
            .Where(h => ids.Contains(h.DonViId))
            .ToListAsync(cancellationToken);
        var hoursByStation = hours.ToLookup(h => h.DonViId);
        var openMap = StationOperationalEvaluator.BuildOpenNowMap(ids, hours, dow, nowTime);
        var priceMap = await fuelReporting.GetMapPriceSnapshotsForStationsAsync(ids, cancellationToken);

        return mapRows.Select(r =>
        {
            var todayH = hoursByStation[r.StationId].Where(h => h.DayOfWeek == dowByte).ToList();
            var openNowWeekly = openMap.TryGetValue(r.StationId, out var on) ? on : null;
            var openNow = r.OpenTime is not null && r.CloseTime is not null
                ? StationOperationalEvaluator.IsOpenNowFromDonViTimes(r.OpenTime, r.CloseTime, nowTime)
                : openNowWeekly;
            var (op, cl) = StationOperationalEvaluator.ResolveDisplayHours(r.OpenTime, r.CloseTime, todayH);
            priceMap.TryGetValue(r.StationId, out var px);
            px ??= new MapStationPrices(null, null);
            activeCodesByStation.TryGetValue(r.StationId, out var svcCodes);
            return new StationMapItemDto(
                r.StationId,
                r.StationName,
                r.Latitude,
                r.Longitude,
                r.ShortAddress,
                px.PriceRon95,
                px.PriceDiesel,
                r.IsActive,
                openNow,
                StationOperationalEvaluator.ToOpenStatus(openNow),
                op,
                cl,
                svcCodes is { Count: > 0 } ? svcCodes : Array.Empty<string>());
        }).ToList();
    }

    private async Task<string?> ValidateProvinceMaExistsAsync(string? provinceTrim, CancellationToken cancellationToken)
    {
        if (provinceTrim is null)
            return null;
        var provinceOk = await db.DmTinhs.AsNoTracking().AnyAsync(t => t.Ma == provinceTrim, cancellationToken);
        return provinceOk ? null : $"Unknown province code '{provinceTrim}' (DM_Tinh.Ma).";
    }

    private sealed record StationListPageRow(
        int StationId,
        string StationCode,
        string StationName,
        string? AddressLine,
        string? ProvinceCode,
        string? ProvinceName,
        string? WardCode,
        string? WardName,
        int? DistrictId,
        string? LicenseNumber,
        bool? IsActive,
        TimeOnly? OpenTime,
        TimeOnly? CloseTime);

    private sealed record StationMapPageRow(
        int StationId,
        string StationName,
        double Latitude,
        double Longitude,
        string? ShortAddress,
        bool? IsActive,
        TimeOnly? OpenTime,
        TimeOnly? CloseTime);
}

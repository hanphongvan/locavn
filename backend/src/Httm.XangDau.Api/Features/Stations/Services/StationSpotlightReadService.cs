using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.FuelReporting.Persistence;
using Httm.XangDau.Api.Features.FuelReporting.Services;
using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Stations.Services;

public sealed class StationSpotlightReadService(
    DmpPortalDbContext db,
    IFuelReportingReadService fuelReporting,
    IStationRetailPriceDataAccess retailBoardPrices) : IStationSpotlightReadService
{
    public async Task<(StationSpotlightDto? Data, string? Error)> GetNearestAsync(
        double lat,
        double lng,
        CancellationToken cancellationToken = default)
    {
        if (!double.IsFinite(lat) || !double.IsFinite(lng))
            return (null, "lat and lng must be finite numbers.");
        if (lat < (double)StationCoordinateRules.MinLatitude || lat > (double)StationCoordinateRules.MaxLatitude
            || lng < (double)StationCoordinateRules.MinLongitude || lng > (double)StationCoordinateRules.MaxLongitude)
            return (null, "lat/lng are outside valid WGS84 bounds.");

        var latDec = (decimal)lat;
        var lngDec = (decimal)lng;

        var row = await db.DmDonVis.AsNoTracking().WherePetrolRetailWithValidMapCoordinates()
            .OrderBy(d =>
                (d.ViDo!.Value - latDec) * (d.ViDo.Value - latDec)
                + (d.KinhDo!.Value - lngDec) * (d.KinhDo.Value - lngDec))
            .Select(d => new { d.Id, d.Ten, Addr = d.DiaChiChiTiet ?? d.DiaChi, d.ViDo, d.KinhDo })
            .FirstOrDefaultAsync(cancellationToken);

        if (row is null)
            return (null, "No petrol station with valid map coordinates was found.");

        var distKm = Math.Round(
            HaversineKm(lat, lng, (double)row.ViDo!.Value, (double)row.KinhDo!.Value),
            3,
            MidpointRounding.AwayFromZero);
        var spotlight = await BuildSpotlightAsync(
            row.Id,
            row.Ten,
            row.Addr,
            distKm,
            ratingAvg: null,
            ratingCount: null,
            cancellationToken);
        return (spotlight, null);
    }

    public async Task<(StationSpotlightDto? Data, string? Error)> GetCheapestAsync(
        string fuelType,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(fuelType))
            return (null, "fuelType is required (e.g. ron95 or diesel).");
        if (!SpotlightFuelTypeParser.TryGetProductCode(fuelType.Trim(), out var productCode, out var parseErr))
            return (null, parseErr!);

        var best = await retailBoardPrices
            .GetCheapestStationByProductCodeAsync(
                productCode,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);
        if (best is null)
            return (null, "No retail board prices matched the requested fuel type (StationPrices / StationProductPrices).");

        var nameAddr = await db.DmDonVis.AsNoTracking()
            .Where(d => d.Id == best.DonViId)
            .Select(d => new { d.Ten, Addr = d.DiaChiChiTiet ?? d.DiaChi })
            .FirstAsync(cancellationToken);

        var dto = await BuildSpotlightAsync(
            best.DonViId,
            nameAddr.Ten,
            nameAddr.Addr,
            distanceKm: null,
            ratingAvg: null,
            ratingCount: null,
            cancellationToken);
        return (dto, null);
    }

    public async Task<(StationSpotlightDto? Data, string? Error)> GetTopRatedAsync(CancellationToken cancellationToken = default)
    {
        var top = await db.StationReviews.AsNoTracking()
            .GroupBy(r => r.StationId)
            .Select(g => new
            {
                StationId = g.Key,
                AvgRating = g.Average(r => (double)r.Rating),
                ReviewCount = g.Count(),
            })
            .OrderByDescending(x => x.AvgRating)
            .ThenByDescending(x => x.ReviewCount)
            .ThenBy(x => x.StationId)
            .FirstOrDefaultAsync(cancellationToken);

        if (top is null)
            return (null, "No station reviews exist yet.");

        var isPetrol = await db.DmDonVis.AsNoTracking()
            .AnyAsync(d => d.Id == top.StationId && d.CapDonViId == PetrolRetailConstants.CapDonViId, cancellationToken);
        if (!isPetrol)
            return (null, "Highest-rated review target is not a petrol retail unit.");

        var nameAddr = await db.DmDonVis.AsNoTracking()
            .Where(d => d.Id == top.StationId)
            .Select(d => new { d.Ten, Addr = d.DiaChiChiTiet ?? d.DiaChi })
            .FirstAsync(cancellationToken);

        var dto = await BuildSpotlightAsync(
            top.StationId,
            nameAddr.Ten,
            nameAddr.Addr,
            distanceKm: null,
            Math.Round(top.AvgRating, 2, MidpointRounding.AwayFromZero),
            top.ReviewCount,
            cancellationToken);
        return (dto, null);
    }

    private async Task<StationSpotlightDto> BuildSpotlightAsync(
        int stationId,
        string name,
        string? address,
        double? distanceKm,
        double? ratingAvg,
        int? ratingCount,
        CancellationToken cancellationToken)
    {
        var priceMap = await fuelReporting.GetMapPriceSnapshotsForStationsAsync(new[] { stationId }, cancellationToken);
        priceMap.TryGetValue(stationId, out var px);
        px ??= new MapStationPrices(null, null);

        if (ratingAvg is null || ratingCount is null)
            (ratingAvg, ratingCount) = await GetRatingAggregateAsync(stationId, cancellationToken);

        return new StationSpotlightDto(
            stationId,
            name,
            address,
            px.PriceRon95,
            px.PriceDiesel,
            ratingAvg,
            ratingCount,
            distanceKm);
    }

    private async Task<(double? Average, int? Count)> GetRatingAggregateAsync(int stationId, CancellationToken cancellationToken)
    {
        var any = await db.StationReviews.AsNoTracking().AnyAsync(r => r.StationId == stationId, cancellationToken);
        if (!any)
            return (null, null);

        var avg = await db.StationReviews.AsNoTracking()
            .Where(r => r.StationId == stationId)
            .AverageAsync(r => (double)r.Rating, cancellationToken);
        var cnt = await db.StationReviews.AsNoTracking()
            .CountAsync(r => r.StationId == stationId, cancellationToken);
        return (Math.Round(avg, 2, MidpointRounding.AwayFromZero), cnt);
    }

    private static double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthKm = 6371.0;
        var p1 = lat1 * (Math.PI / 180.0);
        var p2 = lat2 * (Math.PI / 180.0);
        var dP = p2 - p1;
        var dL = (lon2 - lon1) * (Math.PI / 180.0);
        var a = Math.Sin(dP / 2) * Math.Sin(dP / 2)
                + Math.Cos(p1) * Math.Cos(p2) * Math.Sin(dL / 2) * Math.Sin(dL / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(Math.Max(0, 1 - a)));
        return earthKm * c;
    }

    private static class SpotlightFuelTypeParser
    {
        /// <summary>Mã sản phẩm trong <c>FuelProducts</c> (RON95, DIESEL).</summary>
        public static bool TryGetProductCode(string fuelType, out string productCode, out string? error)
        {
            productCode = null!;
            error = null;
            var s = fuelType.Trim();
            if (s.Equals("ron95", StringComparison.OrdinalIgnoreCase)
                || s.Equals("ron-95", StringComparison.OrdinalIgnoreCase))
            {
                productCode = "RON95";
                return true;
            }

            if (s.Equals("diesel", StringComparison.OrdinalIgnoreCase)
                || s.Equals("dau", StringComparison.OrdinalIgnoreCase))
            {
                productCode = "DIESEL";
                return true;
            }

            error = "fuelType must be 'ron95' or 'diesel'.";
            return false;
        }
    }
}

using System.Globalization;
using System.Security.Claims;
using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.FuelReporting.Services;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;
using Httm.XangDau.Api.Features.Leader.Portal;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.Leader.Services;

public sealed class LeaderMapService(
    ILeaderMapSqlDataAccess mapSql,
    ILeaderHomePortalDashboardDataAccess portal,
    IFuelReportingReadService fuelReporting) : ILeaderMapService
{
    private const double LegacyMatchMaxDeg = 0.08;

    /// <inheritdoc />
    public async Task<LeaderMapDistributorsResponse> GetDistributorsAsync(
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        var units = await mapSql
            .ListDistributorUnitsAsync(PetrolWholesaleConstants.CapDonViId, cancellationToken)
            .ConfigureAwait(false);

        var name = user.FindFirstValue(ClaimTypes.Name) ?? string.Empty;
        var legX = await portal
            .GetDistributorMapAsync(new LeaderHomeDistributorMapRequest(name, "xang"), cancellationToken)
            .ConfigureAwait(false);
        var legD = await portal
            .GetDistributorMapAsync(new LeaderHomeDistributorMapRequest(name, "dau"), cancellationToken)
            .ConfigureAwait(false);

        var items = units
            .Select(u =>
            {
                var mx = BestLegacyMatch(u.ViDo, u.KinhDo, u.TenDonVi, legX.Items);
                var md = BestLegacyMatch(u.ViDo, u.KinhDo, u.TenDonVi, legD.Items);
                var daysX = mx is null ? null : (int?)mx.Days;
                var daysD = md is null ? null : (int?)md.Days;
                return new LeaderMapDistributorDto(
                    u.Id,
                    u.TenDonVi,
                    u.DiaChi,
                    (decimal)u.ViDo,
                    (decimal)u.KinhDo,
                    u.LogoUrl,
                    mx?.Xang ?? 0m,
                    md?.Dau ?? 0m,
                    daysX,
                    daysD,
                    LeaderMapDistributorReserveDisplayStatus.FromDays(daysX),
                    LeaderMapDistributorReserveDisplayStatus.FromDays(daysD));
            })
            .ToList();

        return new LeaderMapDistributorsResponse(items);
    }

    /// <inheritdoc />
    public async Task<(LeaderMapDistributorInventoryResponse? Data, bool NotFound)> GetDistributorInventoryAsync(
        int donViId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (donViId <= 0)
            return (null, true);

        var unit = await mapSql
            .GetDistributorUnitByIdAsync(donViId, PetrolWholesaleConstants.CapDonViId, cancellationToken)
            .ConfigureAwait(false);
        if (unit is null)
            return (null, true);

        var name = user.FindFirstValue(ClaimTypes.Name) ?? string.Empty;
        var legX = await portal
            .GetDistributorMapAsync(new LeaderHomeDistributorMapRequest(name, "xang"), cancellationToken)
            .ConfigureAwait(false);
        var legD = await portal
            .GetDistributorMapAsync(new LeaderHomeDistributorMapRequest(name, "dau"), cancellationToken)
            .ConfigureAwait(false);

        var mx = BestLegacyMatch(unit.ViDo, unit.KinhDo, unit.TenDonVi, legX.Items);
        var md = BestLegacyMatch(unit.ViDo, unit.KinhDo, unit.TenDonVi, legD.Items);
        var daysX = mx is null ? null : (int?)mx.Days;
        var daysD = md is null ? null : (int?)md.Days;

        var dto = new LeaderMapDistributorInventoryResponse(
            unit.Id,
            unit.TenDonVi,
            unit.DiaChi,
            mx?.Xang ?? 0m,
            md?.Dau ?? 0m,
            daysX,
            daysD,
            LeaderMapDistributorReserveDisplayStatus.FromDays(daysX),
            LeaderMapDistributorReserveDisplayStatus.FromDays(daysD));

        return (dto, false);
    }

    /// <inheritdoc />
    public Task<LeaderHomeInventorySummaryResponse> GetInventorySummaryAsync(
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        var req = LeaderPortalAuth.MergeDashboard(user, null);
        return portal.GetInventorySummaryAsync(req, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<LeaderMapPricesResponse> GetPricesAsync(
        IReadOnlyList<int> stationIds,
        CancellationToken cancellationToken = default)
    {
        var map = await fuelReporting
            .GetMapPriceSnapshotsForStationsAsync(stationIds, cancellationToken)
            .ConfigureAwait(false);
        var items = stationIds
            .Distinct()
            .Select(id =>
            {
                map.TryGetValue(id, out var px);
                px ??= new MapStationPrices(null, null);
                return new LeaderMapStationPriceDto(id, px.PriceRon95, px.PriceDiesel);
            })
            .ToList();
        return new LeaderMapPricesResponse(items);
    }

    /// <inheritdoc />
    public async Task<LeaderMapViolationsResponse> GetViolationsAsync(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return new LeaderMapViolationsResponse(stationId, Array.Empty<LeaderMapBadReportDto>());

        var rows = await mapSql.ListBadReportsByStationAsync(stationId, cancellationToken).ConfigureAwait(false);
        var items = rows
            .Select(r => new LeaderMapBadReportDto(
                r.Id,
                r.Content,
                r.CreatedAt,
                MapBadReportStatus(r.Status)))
            .ToList();
        return new LeaderMapViolationsResponse(stationId, items);
    }

    private static string MapBadReportStatus(byte status) =>
        Enum.IsDefined(typeof(StationBadReportStatus), status)
            ? ((StationBadReportStatus)status).ToString()
            : status.ToString(CultureInfo.InvariantCulture);

    private static LeaderHomeDistributorMapRow? BestLegacyMatch(
        double lat,
        double lng,
        string unitName,
        IReadOnlyList<LeaderHomeDistributorMapRow> legacyRows)
    {
        var normUnit = NormalizeName(unitName);
        LeaderHomeDistributorMapRow? byName = null;
        foreach (var r in legacyRows)
        {
            if (string.Equals(NormalizeName(r.Name), normUnit, StringComparison.Ordinal))
            {
                byName = r;
                break;
            }
        }

        if (byName is not null)
            return byName;

        LeaderHomeDistributorMapRow? best = null;
        var bestD = double.MaxValue;
        foreach (var r in legacyRows)
        {
            var d = DegDistance(lat, lng, (double)r.Lat, (double)r.Lng);
            if (d < bestD && d <= LegacyMatchMaxDeg)
            {
                bestD = d;
                best = r;
            }
        }

        return best;
    }

    private static string NormalizeName(string? s) =>
        string.IsNullOrWhiteSpace(s)
            ? string.Empty
            : s.Trim().ToLowerInvariant();

    private static double DegDistance(double lat1, double lng1, double lat2, double lng2)
    {
        var dx = lat1 - lat2;
        var dy = lng1 - lng2;
        return Math.Sqrt(dx * dx + dy * dy);
    }
}

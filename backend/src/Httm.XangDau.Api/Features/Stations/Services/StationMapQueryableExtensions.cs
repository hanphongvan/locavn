using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>Shared map/list coordinate filters (same rules as <c>GET /api/stations/map</c>).</summary>
public static class StationMapQueryableExtensions
{
    public static IQueryable<DmDonVi> WherePetrolRetailCap(this IQueryable<DmDonVi> query) =>
        query.Where(d => d.CapDonViId == PetrolRetailConstants.CapDonViId);

    /// <summary>Stations that can appear on the map: valid non-placeholder WGS84 coordinates.</summary>
    public static IQueryable<DmDonVi> WherePetrolRetailWithValidMapCoordinates(this IQueryable<DmDonVi> query) =>
        query
            .WherePetrolRetailCap()
            .Where(d => d.ViDo != null && d.KinhDo != null)
            .Where(d => d.ViDo >= StationCoordinateRules.MinLatitude && d.ViDo <= StationCoordinateRules.MaxLatitude)
            .Where(d => d.KinhDo >= StationCoordinateRules.MinLongitude && d.KinhDo <= StationCoordinateRules.MaxLongitude)
            .Where(d => !(d.ViDo == 0m && d.KinhDo == 0m));
}

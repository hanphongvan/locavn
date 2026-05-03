namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>
/// Map markers must not expose invalid or placeholder coordinates.
/// Bounds follow WGS84; (0,0) is treated as invalid data for this domain.
/// </summary>
public static class StationCoordinateRules
{
    public const decimal MinLatitude = -90m;
    public const decimal MaxLatitude = 90m;
    public const decimal MinLongitude = -180m;
    public const decimal MaxLongitude = 180m;

    /// <summary>Detail API: only surface coordinates when they pass the same rules as the map endpoint.</summary>
    public static bool TryToDisplayCoordinates(decimal? viDo, decimal? kinhDo, out double latitude, out double longitude)
    {
        latitude = default;
        longitude = default;
        if (viDo is not { } lat || kinhDo is not { } lng)
            return false;
        if (lat < MinLatitude || lat > MaxLatitude || lng < MinLongitude || lng > MaxLongitude)
            return false;
        if (lat == 0m && lng == 0m)
            return false;
        latitude = (double)lat;
        longitude = (double)lng;
        return true;
    }
}

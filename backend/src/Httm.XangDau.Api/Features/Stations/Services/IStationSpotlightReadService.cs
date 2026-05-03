using Httm.XangDau.Api.Features.Stations.Contracts;

namespace Httm.XangDau.Api.Features.Stations.Services;

public interface IStationSpotlightReadService
{
    Task<(StationSpotlightDto? Data, string? Error)> GetNearestAsync(double lat, double lng, CancellationToken cancellationToken = default);

    Task<(StationSpotlightDto? Data, string? Error)> GetCheapestAsync(string fuelType, CancellationToken cancellationToken = default);

    Task<(StationSpotlightDto? Data, string? Error)> GetTopRatedAsync(CancellationToken cancellationToken = default);
}

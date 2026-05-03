using Httm.XangDau.Api.Features.Geography.Contracts;

namespace Httm.XangDau.Api.Features.Geography.Services;

public interface IGeographyReadService
{
    Task<IReadOnlyList<ProvinceResponseDto>> ListProvincesAsync(CancellationToken cancellationToken = default);

    /// <returns>Error message when province not found or invalid code.</returns>
    Task<(IReadOnlyList<DistrictResponseDto>? Data, string? Error)> ListDistrictsAsync(
        string provinceCode,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<WardResponseDto>? Data, string? Error)> ListWardsAsync(
        string districtCode,
        CancellationToken cancellationToken = default);
}

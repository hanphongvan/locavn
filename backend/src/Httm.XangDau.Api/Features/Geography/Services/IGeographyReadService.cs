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

    /// <summary>Toàn bộ xã/phường trong 1 tỉnh (theo mã tỉnh ĐVHCVN). Trả về <c>null</c> nếu tỉnh không tồn tại.</summary>
    Task<(IReadOnlyList<WardResponseDto>? Data, string? Error)> ListWardsByProvinceAsync(
        string provinceCode,
        CancellationToken cancellationToken = default);

    /// <summary>Tra mã tỉnh ĐVHCVN từ <c>DM_DonVi.Tinh</c>. Trả về <c>null</c> nếu không có hoặc đơn vị không tồn tại.</summary>
    Task<string?> GetProvinceCodeByDonViIdAsync(int donViId, CancellationToken cancellationToken = default);
}

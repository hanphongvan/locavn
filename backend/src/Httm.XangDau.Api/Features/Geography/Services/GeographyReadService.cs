using System.Globalization;
using Httm.XangDau.Api.Features.Geography.Contracts;
using Httm.XangDau.Api.Shared.DataAccess.Repositories;

namespace Httm.XangDau.Api.Features.Geography.Services;

public sealed class GeographyReadService(IGeographyRepository geography) : IGeographyReadService
{
    public async Task<IReadOnlyList<ProvinceResponseDto>> ListProvincesAsync(CancellationToken cancellationToken = default)
    {
        var rows = await geography.ListProvincesOrderedAsync(cancellationToken);
        return rows.Select(x => new ProvinceResponseDto(x.Id, x.Ma, x.Ten, x.SapXep, x.VungMien)).ToList();
    }

    public async Task<(IReadOnlyList<DistrictResponseDto>? Data, string? Error)> ListDistrictsAsync(
        string provinceCode,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(provinceCode))
            return (null, "provinceCode is required.");

        var pc = provinceCode.Trim();
        var province = await geography.GetProvinceByMaAsync(pc, cancellationToken);
        if (province is null)
            return (null, $"Province with Ma (provinceCode) '{pc}' was not found in DM_Tinh.");

        var ids = await geography.ListDistrictQuanHuyenIdsForProvinceIdAsync(province.Id, cancellationToken);

        var list = ids
            .Select(id => new DistrictResponseDto(id, id.ToString(CultureInfo.InvariantCulture), null))
            .ToList();

        return (list, null);
    }

    public async Task<(IReadOnlyList<WardResponseDto>? Data, string? Error)> ListWardsAsync(
        string districtCode,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(districtCode))
            return (null, "districtCode is required (numeric QuanHuyenId per DM_XaPhuong.QuanHuyenId).");

        if (!int.TryParse(districtCode.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var qhId))
            return (null, "districtCode must be a numeric QuanHuyenId.");

        var rows = await geography.ListWardsByQuanHuyenIdAsync(qhId, cancellationToken);
        var list = rows.Select(x => new WardResponseDto(x.Ma, x.Ten, x.TinhId, x.QuanHuyenId)).ToList();

        return (list, null);
    }

    public async Task<(IReadOnlyList<WardResponseDto>? Data, string? Error)> ListWardsByProvinceAsync(
        string provinceCode,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(provinceCode))
            return (null, "provinceCode is required.");

        var pc = provinceCode.Trim();
        var province = await geography.GetProvinceByMaAsync(pc, cancellationToken);
        if (province is null)
            return (null, $"Province with Ma '{pc}' was not found in DM_Tinh.");

        var rows = await geography.ListWardsByTinhIdAsync(province.Id, cancellationToken);
        var list = rows.Select(x => new WardResponseDto(x.Ma, x.Ten, x.TinhId, x.QuanHuyenId)).ToList();
        return (list, null);
    }

    public Task<string?> GetProvinceCodeByDonViIdAsync(int donViId, CancellationToken cancellationToken = default) =>
        geography.GetProvinceCodeByDonViIdAsync(donViId, cancellationToken);
}

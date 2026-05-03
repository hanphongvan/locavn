using Httm.XangDau.Api.Shared.DataAccess.Dtos;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public interface IGeographyRepository
{
    Task<IReadOnlyList<ProvinceRowDto>> ListProvincesOrderedAsync(CancellationToken cancellationToken = default);

    Task<ProvinceSummaryRowDto?> GetProvinceByMaAsync(string ma, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<int>> ListDistrictQuanHuyenIdsForProvinceIdAsync(
        int provinceId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<WardRowDto>> ListWardsByQuanHuyenIdAsync(int quanHuyenId, CancellationToken cancellationToken = default);
}

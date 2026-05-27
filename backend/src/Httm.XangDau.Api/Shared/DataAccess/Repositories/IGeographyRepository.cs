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

    /// <summary>Toàn bộ xã/phường trong 1 tỉnh — phục vụ template Excel import (sau 2025 VN bỏ cấp huyện).</summary>
    Task<IReadOnlyList<WardRowDto>> ListWardsByTinhIdAsync(int tinhId, CancellationToken cancellationToken = default);

    /// <summary>Tra mã tỉnh từ <c>DM_DonVi.Tinh</c> theo đơn vị của user. Trả về <c>null</c> nếu đơn vị không có Tinh.</summary>
    Task<string?> GetProvinceCodeByDonViIdAsync(int donViId, CancellationToken cancellationToken = default);
}

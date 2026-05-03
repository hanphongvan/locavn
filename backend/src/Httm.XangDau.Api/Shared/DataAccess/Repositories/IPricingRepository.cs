using Httm.XangDau.Api.Shared.DataAccess.Dtos;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public interface IPricingRepository
{
    Task<IReadOnlyList<KieuKyBaoCaoRowDto>> ListKieuKyBaoCaoOrderedAsync(CancellationToken cancellationToken = default);

    Task<QtTkThongKeRowDto?> GetThongKeByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<QtTkThongKeChiTietRowDto>> ListChiTietByThongKeIdAsync(
        Guid thongKeId,
        CancellationToken cancellationToken = default);
}

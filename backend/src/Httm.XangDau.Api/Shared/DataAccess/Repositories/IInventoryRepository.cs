using Httm.XangDau.Api.Shared.DataAccess.Dtos;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public interface IInventoryRepository
{
    Task<IReadOnlyList<KhoXangDauRowDto>> ListKhosByDonViIdAsync(int donViId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PhanBoDungTichRowDto>> ListPhanBoByKhoIdAsync(Guid khoId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<TonKhoRowDto>> ListTonKhoByPhanBoIdAsync(Guid phanBoId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<HopDongKhoRowDto>> ListHopDongByPhanBoIdAsync(Guid phanBoId, CancellationToken cancellationToken = default);
}

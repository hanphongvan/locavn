using Httm.XangDau.Api.Shared.DataAccess.Dtos;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public interface IStationRepository
{
    Task<DonViRowDto?> GetDonViByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<bool> AnyDonViWithCapAsync(int id, int capDonViId, CancellationToken cancellationToken = default);
}

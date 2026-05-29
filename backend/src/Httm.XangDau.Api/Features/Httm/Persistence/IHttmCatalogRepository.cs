using Httm.XangDau.Api.Features.Httm.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Persistence;

public interface IHttmCatalogRepository
{
    Task<IReadOnlyList<HttmCatalogItemDto>> GetByTypeAsync(
        string type,
        bool activeOnly,
        CancellationToken cancellationToken = default);
}

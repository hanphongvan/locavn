using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Stations.Services;

public sealed class FuelProductReadService(DmpPortalDbContext db) : IFuelProductReadService
{
    public async Task<IReadOnlyList<FuelProductLeafDto>> GetActiveLeavesAsync(CancellationToken cancellationToken = default)
    {
        // Lá = Id không xuất hiện trong tập ParentId. NOT EXISTS giữ index seek trên FuelProducts.Id.
        var rows = await (
            from p in db.FuelProducts.AsNoTracking()
            where p.IsActive
                  && !db.FuelProducts.AsNoTracking().Any(c => c.ParentId == p.Id)
            join parent in db.FuelProducts.AsNoTracking() on p.ParentId equals parent.Id into pg
            from parent in pg.DefaultIfEmpty()
            orderby p.SortOrder, p.Name
            select new FuelProductLeafDto(
                p.Code,
                p.Name,
                parent != null ? parent.Code : null,
                p.SortOrder ?? 0)
        ).ToListAsync(cancellationToken);

        return rows;
    }
}

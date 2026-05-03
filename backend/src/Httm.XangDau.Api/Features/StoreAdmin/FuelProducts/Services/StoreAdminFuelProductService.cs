using System.ComponentModel.DataAnnotations;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Services;

public sealed class StoreAdminFuelProductService(IStoreAdminFuelProductRepository repository)
    : IStoreAdminFuelProductService
{
    public async Task<(StoreAdminFuelProductListPageDto? Data, string? Error)> ListAsync(
        int skip,
        int take,
        bool? isActive,
        bool leavesOnly = true,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminFuelProductValidator.ValidatePagination(skip, take);
        if (err is not null)
            return (null, err);

        var (items, total) = await repository
            .ListAsync(skip, take, isActive, leavesOnly, cancellationToken)
            .ConfigureAwait(false);
        return (new StoreAdminFuelProductListPageDto(items, total, skip, take), null);
    }

    public async Task<(IReadOnlyList<StoreAdminFuelProductTreeNodeDto>? Data, string? Error)> GetTreeAsync(
        CancellationToken cancellationToken = default)
    {
        var rows = await repository.GetAllForTreeAsync(cancellationToken).ConfigureAwait(false);
        var tree = BuildTree(rows);
        return (tree, null);
    }

    public async Task<(StoreAdminFuelProductDetailDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var dto = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return dto is null ? (null, null, true) : (dto, null, false);
    }

    public async Task<(StoreAdminFuelProductDetailDto? Data, string? Error)> CreateAsync(
        StoreAdminFuelProductUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err);

        if (await repository.CodeExistsAsync(body.Code, null, cancellationToken).ConfigureAwait(false))
            return (null, "Code already exists.");

        if (body.ParentId is int pid)
        {
            if (!await repository.IdExistsAsync(pid, cancellationToken).ConfigureAwait(false))
                return (null, "ParentId does not reference an existing FuelProducts row.");
        }

        var now = DateTime.UtcNow;
        var entity = new FuelProduct
        {
            Code = body.Code.Trim(),
            Name = body.Name.Trim(),
            ParentId = body.ParentId,
            UnitId = body.UnitId,
            IsActive = body.IsActive,
            SortOrder = body.SortOrder,
            Description = TrimOrNull(body.Description),
            Created = now,
            Modified = now,
            CreatedBy = "api-admin",
            ModifiedBy = "api-admin",
        };

        await repository.AddAsync(entity, cancellationToken).ConfigureAwait(false);
        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        var dto = await repository.GetByIdAsync(entity.Id, cancellationToken).ConfigureAwait(false);
        return (dto, null);
    }

    public async Task<(StoreAdminFuelProductDetailDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminFuelProductUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err, false);

        var entity = await repository.GetTrackedByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (entity is null)
            return (null, null, true);

        if (await repository.CodeExistsAsync(body.Code, id, cancellationToken).ConfigureAwait(false))
            return (null, "Code already exists.", false);

        if (body.ParentId == id)
            return (null, "ParentId cannot equal the product Id.", false);

        if (body.ParentId is int pid)
        {
            if (!await repository.IdExistsAsync(pid, cancellationToken).ConfigureAwait(false))
                return (null, "ParentId does not reference an existing FuelProducts row.", false);

            var parentMap = await repository.GetParentMapAsync(cancellationToken).ConfigureAwait(false);
            if (StoreAdminFuelProductValidator.ParentWouldCreateCycle(id, pid, parentMap))
                return (null, "ParentId would create a cycle in the product tree.", false);
        }

        entity.Code = body.Code.Trim();
        entity.Name = body.Name.Trim();
        entity.ParentId = body.ParentId;
        entity.UnitId = body.UnitId;
        entity.IsActive = body.IsActive;
        entity.SortOrder = body.SortOrder;
        entity.Description = TrimOrNull(body.Description);
        entity.Modified = DateTime.UtcNow;
        entity.ModifiedBy = "api-admin";

        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        var dto = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return (dto, null, false);
    }

    private static IReadOnlyList<StoreAdminFuelProductTreeNodeDto> BuildTree(IReadOnlyList<FuelProduct> rows)
    {
        var byParent = rows.ToLookup(x => x.ParentId);

        StoreAdminFuelProductTreeNodeDto Build(FuelProduct p)
        {
            var orderedChildren = byParent[p.Id].OrderBy(x => x.SortOrder).ThenBy(x => x.Code).ToList();
            var children = orderedChildren.Count == 0
                ? (IReadOnlyList<StoreAdminFuelProductTreeNodeDto>)Array.Empty<StoreAdminFuelProductTreeNodeDto>()
                : orderedChildren.Select(Build).ToList();

            return new StoreAdminFuelProductTreeNodeDto(
                p.Id,
                p.Code,
                p.Name,
                p.ParentId,
                p.UnitId,
                p.IsActive,
                p.SortOrder,
                p.Description,
                children);
        }

        var roots = byParent[null].OrderBy(x => x.SortOrder).ThenBy(x => x.Code).ToList();
        return roots.Count == 0 ? Array.Empty<StoreAdminFuelProductTreeNodeDto>() : roots.Select(Build).ToList();
    }

    private static string? ValidateRequest(StoreAdminFuelProductUpsertRequest body)
    {
        var ctx = new ValidationContext(body);
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(body, ctx, results, validateAllProperties: true))
            return string.Join(" ", results.Select(r => r.ErrorMessage).Where(m => !string.IsNullOrEmpty(m)));

        return StoreAdminFuelProductValidator.ValidateUpsert(body);
    }

    private static void Normalize(StoreAdminFuelProductUpsertRequest body)
    {
        body.Code = body.Code?.Trim() ?? string.Empty;
        body.Name = body.Name?.Trim() ?? string.Empty;
        body.Description = TrimOrNull(body.Description);
    }

    private static string? TrimOrNull(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}

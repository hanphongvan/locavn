using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Persistence;
using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Services;

public sealed class DemoDataMutationService(IDemoDataRepository repository) : IDemoDataMutationService
{
    public async Task<DemoDataOperationResponse> ClearAsync(DemoDataCommandRequest request, CancellationToken cancellationToken = default)
    {
        var err = ValidateTinh(request.Tinh);
        if (err is not null)
            return Fail(err);

        var (ok, sqlErr) = await repository
            .ClearAsync(request.Tinh, PetrolRetailConstants.CapDonViId, cancellationToken)
            .ConfigureAwait(false);
        return ok ? Ok() : Fail(sqlErr ?? "Stored procedure failed.");
    }

    public async Task<DemoDataOperationResponse> GeneratePricesAsync(
        DemoDataCommandRequest request,
        CancellationToken cancellationToken = default)
    {
        var err = ValidateGenerate(request);
        if (err is not null)
            return Fail(err);

        var (ok, sqlErr) = await repository
            .GeneratePricesAsync(
                request.Tinh,
                request.ClearOldData,
                request.Days,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);
        return ok ? Ok() : Fail(sqlErr ?? "Stored procedure failed.");
    }

    public async Task<DemoDataOperationResponse> GenerateInventoryAsync(
        DemoDataCommandRequest request,
        CancellationToken cancellationToken = default)
    {
        var err = ValidateGenerate(request);
        if (err is not null)
            return Fail(err);

        var (ok, sqlErr) = await repository
            .GenerateInventoryAsync(
                request.Tinh,
                request.ClearOldData,
                request.Days,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);
        return ok ? Ok() : Fail(sqlErr ?? "Stored procedure failed.");
    }

    public async Task<DemoDataOperationResponse> GenerateAllAsync(
        DemoDataCommandRequest request,
        CancellationToken cancellationToken = default)
    {
        var err = ValidateGenerate(request);
        if (err is not null)
            return Fail(err);

        var (ok, sqlErr) = await repository
            .GenerateAllAsync(
                request.Tinh,
                request.ClearOldData,
                request.Days,
                PetrolRetailConstants.CapDonViId,
                cancellationToken)
            .ConfigureAwait(false);
        return ok ? Ok() : Fail(sqlErr ?? "Stored procedure failed.");
    }

    private static DemoDataOperationResponse Ok() =>
        new(true, null, DateTimeOffset.UtcNow);

    private static DemoDataOperationResponse Fail(string message) =>
        new(false, message, DateTimeOffset.UtcNow);

    private static string? ValidateTinh(int tinh) =>
        tinh < 1 ? "Tinh must be a positive province key (DM_DonVi.Tinh / DM_Tinh.Id)." : null;

    private static string? ValidateGenerate(DemoDataCommandRequest request)
    {
        var tinhErr = ValidateTinh(request.Tinh);
        if (tinhErr is not null)
            return tinhErr;

        if (request.Days < 1 || request.Days > 400)
            return "Days must be between 1 and 400.";

        return null;
    }
}

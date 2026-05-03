namespace Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Contracts;

/// <summary>Current portal user for Angular store-admin bootstrap (JWT identity + <c>AspNetUsers</c> / <c>DM_DonVi</c>).</summary>
/// <param name="DonViId"><c>0</c> when the user is the built-in root account <c>system</c> (no retail <c>DM_DonVi</c>).</param>
public sealed record StoreAdminMeDto(
    string UserName,
    string? DisplayName,
    string? Email,
    int DonViId,
    string StoreName,
    bool IsStoreAdmin);

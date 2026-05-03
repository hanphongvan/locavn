using Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;

namespace Httm.XangDau.Api.Features.Admin.UserManagement.Persistence;

/// <summary>
/// Legacy HT stored procedures + minimal direct SQL on <c>AspNetUsers</c> where SPs are unknown.
/// TODO(legacy-db): Align every Dapper parameter name with your real procedure signatures.
/// </summary>
public interface ILegacyHtUserRepository
{
    Task<(IReadOnlyList<UserListItemDto> Items, int TotalCount)> GetUsersModelAsync(
        string callerUserName,
        string? keyword,
        int? donViId,
        int? loai,
        bool? locked,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<UserDetailDto?> GetUserByIdAsync(string id, CancellationToken cancellationToken = default);

    Task<string?> AddOrUpdateUserAsync(
        string? id,
        string userName,
        string? displayName,
        string? fullName,
        string? email,
        string? phone,
        string? address,
        string? description,
        int? donViId,
        int? loai,
        string? passwordPlain,
        string? passwordHash,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteUserAsync(string id, CancellationToken cancellationToken = default);

    Task<int> SetLockoutEnabledAsync(IReadOnlyList<string> userIds, bool enabled, CancellationToken cancellationToken = default);

    Task SyncHoSoNhanSuAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<RoleOptionDto>> GetRolesAllAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DonViOptionDto>> GetDonViListAsync(CancellationToken cancellationToken = default);

    /// <summary>Legacy <c>sp_DM_DonVi_GetAllOrderbyMaAo</c> scoped by portal user (<paramref name="userName"/>).</summary>
    Task<IReadOnlyList<DonViOptionDto>> GetDonViBySpDmDonViGetAllOrderbyMaAoAsync(
        string userName,
        CancellationToken cancellationToken = default);

    /// <summary>Petrol retail stores: <c>DM_DonVi.CapDonViId</c> = <c>PetrolRetailConstants.CapDonViId</c>.</summary>
    Task<IReadOnlyList<DonViOptionDto>> GetDonViPetrolRetailStoresAsync(CancellationToken cancellationToken = default);

    Task ReplaceUserRolesAsync(string userId, IReadOnlyList<string> roleIds, CancellationToken cancellationToken = default);

    Task ReplaceUserDonVisAsync(string userId, IReadOnlyList<int> donViIds, CancellationToken cancellationToken = default);
}

namespace Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;

public interface IUserManagementService
{
    Task<(UserListPageDto? Data, string? Error)> ListAsync(
        string? keyword,
        int? donViId,
        int? loai,
        bool? locked,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(UserDetailDto? Data, string? Error)> GetByIdAsync(string id, CancellationToken cancellationToken = default);

    Task<(string? NewId, string? Error)> CreateAsync(UserCreateRequest request, CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error)> UpdateAsync(string id, UserUpdateRequest request, CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error)> DeleteAsync(string id, CancellationToken cancellationToken = default);

    Task<(UserLockUnlockResultDto? Data, string? Error)> LockAsync(
        UserBulkIdsRequest request,
        CancellationToken cancellationToken = default);

    Task<(UserLockUnlockResultDto? Data, string? Error)> UnlockAsync(
        UserBulkIdsRequest request,
        CancellationToken cancellationToken = default);

    Task<(UserSyncResultDto? Data, string? Error)> SyncAsync(CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<RoleOptionDto>? Data, string? Error)> ListRolesAsync(CancellationToken cancellationToken = default);

    /// <param name="forLoai">When set to Admin (1), Trader (3), or Store (4), returns options for user forms; otherwise all <c>DM_DonVi</c> rows.</param>
    Task<(IReadOnlyList<DonViOptionDto>? Data, string? Error)> ListDonViAsync(
        int? forLoai = null,
        CancellationToken cancellationToken = default);
}

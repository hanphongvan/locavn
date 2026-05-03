namespace Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;

/// <summary>Paged list envelope for <c>GET /api/users</c>.</summary>
public sealed record UserListPageDto(IReadOnlyList<UserListItemDto> Items, int TotalCount, int Skip, int Take);

/// <summary>Grid row — map columns from <c>sp_HT_Users_GetModel</c> (aliases recommended; see repository TODO).</summary>
public sealed record UserListItemDto(
    string Id,
    string UserName,
    string? DisplayName,
    int? Loai,
    string? LoaiLabel,
    int? DonViId,
    string? DonViDisplayName,
    bool IsLocked);

public sealed record UserDetailDto(
    string Id,
    string UserName,
    string? FullName,
    string? DisplayName,
    string? Email,
    string? Phone,
    string? Address,
    string? Description,
    bool IsLocked,
    int? DonViId,
    string? DonViDisplayName,
    int? Loai,
    string? LoaiLabel,
    IReadOnlyList<UserRoleAssignmentDto> Roles,
    IReadOnlyList<UserDonViAssignmentDto> DonVis);

public sealed record UserRoleAssignmentDto(string RoleId, string? RoleName);

public sealed record UserDonViAssignmentDto(int DonViId, string? Ma, string? Ten);

public sealed record RoleOptionDto(string Id, string Name);

public sealed record DonViOptionDto(int Id, string Ma, string Ten);

public sealed record UserBulkIdsRequest(IReadOnlyList<string> UserIds);

public sealed record UserLockUnlockResultDto(int Affected);

public sealed record UserSyncResultDto(string Message);

public sealed record UserCreateRequest(
    string UserName,
    string? DisplayName,
    string? FullName,
    string? Email,
    string? Phone,
    string? Address,
    string? Description,
    string Password,
    int? DonViId,
    int? Loai,
    IReadOnlyList<string>? RoleIds,
    IReadOnlyList<int>? DonViIds);

public sealed record UserUpdateRequest(
    string? DisplayName,
    string? FullName,
    string? Email,
    string? Phone,
    string? Address,
    string? Description,
    string? Password,
    int? DonViId,
    int? Loai,
    IReadOnlyList<string>? RoleIds,
    IReadOnlyList<int>? DonViIds);

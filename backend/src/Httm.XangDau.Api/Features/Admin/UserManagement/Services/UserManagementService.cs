using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;
using Httm.XangDau.Api.Features.Admin.UserManagement.Persistence;
using Httm.XangDau.Api.Features.Auth.Registration;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Admin.UserManagement.Services;

public sealed class UserManagementService(
    ILegacyHtUserRepository legacy,
    IAdminPortalRequestContext portal,
    IConfiguration configuration)
    : IUserManagementService
{
    public Task<(UserListPageDto? Data, string? Error)> ListAsync(
        string? keyword,
        int? donViId,
        int? loai,
        bool? locked,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return Task.FromResult<(UserListPageDto?, string?)>((null, err));
        }

        if (skip < 0 || take < 0)
        {
            return Task.FromResult<(UserListPageDto?, string?)>((null, "skip and take must be non-negative."));
        }

        return ListCoreAsync(keyword, donViId, loai, locked, skip, take, cancellationToken);
    }

    private async Task<(UserListPageDto? Data, string? Error)> ListCoreAsync(
        string? keyword,
        int? donViId,
        int? loai,
        bool? locked,
        int skip,
        int take,
        CancellationToken cancellationToken)
    {
        try
        {
            var caller = ResolveCallerUserNameForList();
            if (caller is null)
            {
                return (null, "Không xác định được tài khoản gọi danh sách (thiếu UserName trên JWT).");
            }

            var (items, total) = await legacy
                .GetUsersModelAsync(caller, keyword, donViId, loai, locked, skip, take, cancellationToken)
                .ConfigureAwait(false);
            return (new UserListPageDto(items, total, skip, take), null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(UserDetailDto? Data, string? Error)> GetByIdAsync(string id, CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        if (string.IsNullOrWhiteSpace(id))
        {
            return (null, "id is required.");
        }

        try
        {
            var row = await legacy.GetUserByIdAsync(id.Trim(), cancellationToken).ConfigureAwait(false);
            return (row, row is null ? "User not found." : null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(string? NewId, string? Error)> CreateAsync(UserCreateRequest request, CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        var v = ValidateCreate(request);
        if (v is not null)
        {
            return (null, v);
        }

        var newId = Guid.NewGuid().ToString("D");
        try
        {
            // Hash mật khẩu bằng Identity v2 format (PBKDF2-SHA1, 1000 iter) — đồng bộ với flow Flutter LocaVN
            // (UserRegistrationService.RegisterAsync) và ApplicationOAuthProvider verify khi đăng nhập.
            // SP sp_HT_Users_AddOrUpdate (INSERT path) sẽ ghi: AspNetUsers.PasswordHash = @Password,
            // SecurityStamp = @PasswordSalt — caller hash trước rồi truyền vào passwordHash.
            var passwordHash = LegacyAspNetIdentityV2PasswordHasher.HashPassword(request.Password);

            _ = await legacy
                .AddOrUpdateUserAsync(
                    newId,
                    request.UserName.Trim(),
                    request.DisplayName,
                    request.FullName,
                    request.Email,
                    request.Phone,
                    request.Address,
                    request.Description,
                    request.DonViId,
                    request.Loai,
                    passwordPlain: null,
                    passwordHash: passwordHash,
                    cancellationToken)
                .ConfigureAwait(false);

            if (request.RoleIds is { Count: > 0 })
            {
                await legacy.ReplaceUserRolesAsync(newId, request.RoleIds, cancellationToken).ConfigureAwait(false);
            }

            if (request.DonViIds is { Count: > 0 })
            {
                await legacy.ReplaceUserDonVisAsync(newId, request.DonViIds, cancellationToken).ConfigureAwait(false);
            }

            return (newId, null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(bool Ok, string? Error)> UpdateAsync(string id, UserUpdateRequest request, CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (false, err);
        }

        if (string.IsNullOrWhiteSpace(id))
        {
            return (false, "id is required.");
        }

        var v = ValidateUpdate(request);
        if (v is not null)
        {
            return (false, v);
        }

        try
        {
            var existing = await legacy.GetUserByIdAsync(id.Trim(), cancellationToken).ConfigureAwait(false);
            if (existing is null)
            {
                return (false, "User not found.");
            }

            // Chỉ hash khi caller có gửi password mới (UpdateRequest.Password rỗng = giữ nguyên).
            var passwordHash = string.IsNullOrEmpty(request.Password)
                ? null
                : LegacyAspNetIdentityV2PasswordHasher.HashPassword(request.Password);

            _ = await legacy
                .AddOrUpdateUserAsync(
                    id.Trim(),
                    existing.UserName,
                    request.DisplayName,
                    request.FullName,
                    request.Email,
                    request.Phone,
                    request.Address,
                    request.Description,
                    request.DonViId,
                    request.Loai,
                    passwordPlain: null,
                    passwordHash: passwordHash,
                    cancellationToken)
                .ConfigureAwait(false);

            if (request.RoleIds is not null)
            {
                await legacy.ReplaceUserRolesAsync(id.Trim(), request.RoleIds, cancellationToken).ConfigureAwait(false);
            }

            if (request.DonViIds is not null)
            {
                await legacy.ReplaceUserDonVisAsync(id.Trim(), request.DonViIds, cancellationToken).ConfigureAwait(false);
            }

            return (true, null);
        }
        catch (Exception ex)
        {
            return (false, ex.Message);
        }
    }

    public async Task<(bool Ok, string? Error)> DeleteAsync(string id, CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (false, err);
        }

        if (string.IsNullOrWhiteSpace(id))
        {
            return (false, "id is required.");
        }

        try
        {
            var ok = await legacy.DeleteUserAsync(id.Trim(), cancellationToken).ConfigureAwait(false);
            return ok ? (true, null) : (false, "Delete did not affect a row (user missing or SP rules).");
        }
        catch (Exception ex)
        {
            return (false, ex.Message);
        }
    }

    public async Task<(UserLockUnlockResultDto? Data, string? Error)> LockAsync(
        UserBulkIdsRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        if (request.UserIds.Count == 0)
        {
            return (null, "At least one user id is required.");
        }

        try
        {
            var n = await legacy.SetLockoutEnabledAsync(request.UserIds, true, cancellationToken).ConfigureAwait(false);
            return (new UserLockUnlockResultDto(n), null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(UserLockUnlockResultDto? Data, string? Error)> UnlockAsync(
        UserBulkIdsRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        if (request.UserIds.Count == 0)
        {
            return (null, "At least one user id is required.");
        }

        try
        {
            var n = await legacy.SetLockoutEnabledAsync(request.UserIds, false, cancellationToken).ConfigureAwait(false);
            return (new UserLockUnlockResultDto(n), null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(UserSyncResultDto? Data, string? Error)> SyncAsync(CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        try
        {
            await legacy.SyncHoSoNhanSuAsync(cancellationToken).ConfigureAwait(false);
            return (new UserSyncResultDto("Đồng bộ hồ sơ nhân sự đã được kích hoạt."), null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(IReadOnlyList<RoleOptionDto>? Data, string? Error)> ListRolesAsync(CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        try
        {
            var rows = await legacy.GetRolesAllAsync(cancellationToken).ConfigureAwait(false);
            return (rows, null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(IReadOnlyList<DonViOptionDto>? Data, string? Error)> ListDonViAsync(
        int? forLoai = null,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureAdmin(out var err))
        {
            return (null, err);
        }

        try
        {
            if (forLoai is null)
            {
                var all = await legacy.GetDonViListAsync(cancellationToken).ConfigureAwait(false);
                return (all, null);
            }

            if (forLoai == AdminPortalLoaiRoleMapper.LoaiAdmin || forLoai == AdminPortalLoaiRoleMapper.LoaiTrader)
            {
                var caller = ResolveCallerUserNameForList();
                if (string.IsNullOrWhiteSpace(caller))
                {
                    return (
                        null,
                        "Thiếu UserName để tải đơn vị (đăng nhập Bearer hoặc cấu hình UserManagement:ListUsersCallerUserName khi dùng API key).");
                }

                var scoped = await legacy
                    .GetDonViBySpDmDonViGetAllOrderbyMaAoAsync(caller, cancellationToken)
                    .ConfigureAwait(false);
                return (scoped, null);
            }

            if (forLoai == AdminPortalLoaiRoleMapper.LoaiStore)
            {
                var stores = await legacy.GetDonViPetrolRetailStoresAsync(cancellationToken).ConfigureAwait(false);
                return (stores, null);
            }

            if (forLoai == AdminPortalLoaiRoleMapper.LoaiSoStaff)
            {
                var soUnits = await legacy.GetDonViSoStaffAsync(cancellationToken).ConfigureAwait(false);
                return (soUnits, null);
            }

            return (Array.Empty<DonViOptionDto>(), null);
        }
        catch (Exception ex)
        {
            return (null, ex.Message);
        }
    }

    /// <summary>
    /// Legacy <c>sp_HT_Users_GetModel</c> scopes rows by caller's <c>UserName</c>. API key has no user — use
    /// <c>UserManagement:ListUsersCallerUserName</c> (default <c>admin</c>) so the procedure resolves <c>Loai</c>/<c>DonViId</c>.
    /// </summary>
    private string? ResolveCallerUserNameForList()
    {
        if (portal.IsMachineFullAccess)
        {
            var configured = configuration["UserManagement:ListUsersCallerUserName"];
            return string.IsNullOrWhiteSpace(configured) ? "admin" : configured.Trim();
        }

        return string.IsNullOrWhiteSpace(portal.UserName) ? null : portal.UserName.Trim();
    }

    private bool EnsureAdmin(out string? error)
    {
        if (portal.IsMachineFullAccess)
        {
            error = null;
            return true;
        }

        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiAdmin)
        {
            error = null;
            return true;
        }

        error = "Chỉ tài khoản Admin (Loai=1) hoặc API key máy được quản lý người dùng.";
        return false;
    }

    private static string? ValidateCreate(UserCreateRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.UserName))
        {
            return "UserName is required.";
        }

        if (string.IsNullOrEmpty(r.Password))
        {
            return "Password is required when creating a user.";
        }

        if (r.Loai is int lo && (lo == AdminPortalLoaiRoleMapper.LoaiTrader || lo == AdminPortalLoaiRoleMapper.LoaiStore) && r.DonViId is null)
        {
            return "DonViId is required for Loai 3 (TRADER) or 4 (STORE).";
        }

        if (!string.IsNullOrWhiteSpace(r.Email) && !IsPlausibleEmail(r.Email))
        {
            return "Email format is invalid.";
        }

        return null;
    }

    private static string? ValidateUpdate(UserUpdateRequest r)
    {
        if (!string.IsNullOrWhiteSpace(r.Email) && !IsPlausibleEmail(r.Email))
        {
            return "Email format is invalid.";
        }

        if (r.Loai is int lo && (lo == AdminPortalLoaiRoleMapper.LoaiTrader || lo == AdminPortalLoaiRoleMapper.LoaiStore) && r.DonViId is null)
        {
            return "DonViId is required when Loai is 3 or 4.";
        }

        return null;
    }

    private static bool IsPlausibleEmail(string email)
    {
        var e = email.Trim();
        var at = e.IndexOf('@', StringComparison.Ordinal);
        return at > 0 && at < e.Length - 1;
    }
}

using System.Data;
using System.Globalization;
using Dapper;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Legacy;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.Data.SqlClient;

namespace Httm.XangDau.Api.Features.Admin.UserManagement.Persistence;

/// <summary>
/// Calls legacy HT stored procedures on the same DMPPortal database as EF.
/// <para>
/// TODO(legacy-db): Open each procedure in SSMS and align every <c>p.Add(...)</c> name + types below.
/// User list uses <c>sp_HT_Users_GetModel_Portal</c>, created by EF migration
/// <c>AddHtUsersGetModelPortalStoredProcedure</c> (same script as <c>database/legacy/sp_HT_Users_GetModel_Portal.sql</c>).
/// </para>
/// </summary>
public sealed class LegacyHtUserRepository(IConfiguration configuration, IAdminPortalRequestContext portal)
    : ILegacyHtUserRepository
{
    private const string UsersListPortalProc = "sp_HT_Users_GetModel_Portal";

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<(IReadOnlyList<UserListItemDto> Items, int TotalCount)> GetUsersModelAsync(
        string callerUserName,
        string? keyword,
        int? donViId,
        int? loai,
        bool? locked,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var pageSize = take < 1 ? 20 : Math.Min(take, 500);
        var pageIndex = pageSize > 0 ? skip / pageSize + 1 : 1;

        return await QueryUsersViaPortalProcedureAsync(
                conn,
                callerUserName,
                keyword,
                donViId,
                loai,
                locked,
                pageIndex,
                pageSize,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private static async Task<(IReadOnlyList<UserListItemDto> Items, int TotalCount)> QueryUsersViaPortalProcedureAsync(
        SqlConnection conn,
        string callerUserName,
        string? keyword,
        int? donViId,
        int? loai,
        bool? locked,
        int pageIndex,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var p = new DynamicParameters();
        p.Add("CallerUserName", callerUserName);
        p.Add("TuKhoa", keyword);
        p.Add("DonViId", donViId);
        p.Add("Loai", loai);
        p.Add("KhoaTaiKhoan", locked);
        p.Add("PageIndex", pageIndex);
        p.Add("PageSize", pageSize);
        p.Add("TotalRow", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var rows = await conn
            .QueryAsync(
                UsersListPortalProc,
                p,
                commandType: CommandType.StoredProcedure)
            .ConfigureAwait(false);

        var items = new List<UserListItemDto>();
        foreach (var row in rows)
        {
            var d = (IDictionary<string, object>)row;
            items.Add(MapListRow(d));
        }

        var total = p.Get<int?>("TotalRow");
        if (total is null || total < 0)
        {
            total = items.Count;
        }

        return (items, total.Value);
    }

    public async Task<UserDetailDto?> GetUserByIdAsync(string id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var p = new DynamicParameters();
        p.Add("Id", id);

        await using var multi = await conn
            .QueryMultipleAsync(
                "sp_HT_Users_GetById",
                p,
                commandType: CommandType.StoredProcedure)
            .ConfigureAwait(false);

        var head = await multi.ReadFirstOrDefaultAsync().ConfigureAwait(false);
        if (head is null)
        {
            return null;
        }

        var d = (IDictionary<string, object>)head;
        var roles = new List<UserRoleAssignmentDto>();
        var donVis = new List<UserDonViAssignmentDto>();
        try
        {
            roles = (await multi.ReadAsync().ConfigureAwait(false))
                .Select(r => MapRoleRow((IDictionary<string, object>)r))
                .ToList();
            donVis = (await multi.ReadAsync().ConfigureAwait(false))
                .Select(r => MapDonViRow((IDictionary<string, object>)r))
                .ToList();
        }
        catch (InvalidOperationException)
        {
            // TODO(legacy-db): sp_HT_Users_GetById may return only one grid — extend SP to return roles + DVs as separate sets.
        }

        return MapDetail(d, roles, donVis);
    }

    /// <summary>
    /// Ghi vào <c>AspNetUsers</c> (Identity table) qua <c>sp_HT_Users_AddOrUpdate</c>.
    /// Lưu ý: <c>sp_HT_Users_AddOrUpdatePass</c> ghi vào bảng legacy <c>HT_Users</c>, KHÔNG liên quan đến
    /// đăng nhập Bearer/Identity — không dùng ở đây.
    /// </summary>
    /// <remarks>
    /// SP mapping (theo source thực tế):
    /// <list type="bullet">
    ///   <item><description>INSERT path: <c>AspNetUsers.PasswordHash = @Password</c>, <c>SecurityStamp = @PasswordSalt</c>;
    ///     <c>LockoutEnabled = 0</c> (SP hardcode).</description></item>
    ///   <item><description>UPDATE path: chỉ ghi PasswordHash/SecurityStamp khi <c>@Password</c>/<c>@PasswordSalt</c> không rỗng.</description></item>
    /// </list>
    /// Caller phải hash password bằng <c>LegacyAspNetIdentityV2PasswordHasher.HashPassword</c> và truyền vào
    /// <paramref name="passwordHash"/> (recommended) hoặc <paramref name="passwordPlain"/> (SP sẽ lưu nguyên — không verify được).
    /// </remarks>
    public async Task<string?> AddOrUpdateUserAsync(
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
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(id))
            throw new InvalidOperationException("Id is required for sp_HT_Users_AddOrUpdate.");

        var passwordForSp = !string.IsNullOrEmpty(passwordHash) ? passwordHash
                            : !string.IsNullOrEmpty(passwordPlain) ? passwordPlain
                            : string.Empty;

        // SecurityStamp = NEWID() khi caller gửi password mới (INSERT hoặc UPDATE password);
        // empty khi UPDATE giữ nguyên password (SP UPDATE path bỏ qua nếu @PasswordSalt = '').
        var securityStampForSp = passwordForSp.Length == 0 ? string.Empty : Guid.NewGuid().ToString("D");

        var now = DateTime.Now;
        var actor = string.IsNullOrWhiteSpace(portal.UserName) ? "API" : portal.UserName.Trim();

        object idArg = id;
        if (Guid.TryParse(id, out var idGuid))
            idArg = idGuid;

        var p = new DynamicParameters();
        p.Add("Id", idArg);
        p.Add("UserName", userName);
        p.Add("FullName", fullName);
        p.Add("Password", passwordForSp);
        p.Add("PasswordSalt", securityStampForSp);
        p.Add("DisplayName", displayName);
        p.Add("Description", description);
        p.Add("Phone", phone);
        p.Add("Address", address);
        p.Add("Email", email);
        p.Add("IsActived", true);
        p.Add("IsDefault", false);
        p.Add("Ma_Ao", (string?)null);
        p.Add("Don_Vi_Id", donViId);
        p.Add("Quan_Ly_Id", (Guid?)null);
        p.Add("Loai", loai);
        p.Add("Created", now);
        p.Add("CreatedBy", actor);
        p.Add("Modified", now);
        p.Add("ModifiedBy", actor);

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await conn
            .ExecuteAsync("sp_HT_Users_AddOrUpdate", p, commandType: CommandType.StoredProcedure)
            .ConfigureAwait(false);

        return id;
    }

    public async Task<bool> DeleteUserAsync(string id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var n = await conn.ExecuteAsync(
                "sp_HT_Users_Delete",
                new DynamicParameters(new { Id = id }),
                commandType: CommandType.StoredProcedure)
            .ConfigureAwait(false);
        return n > 0;
    }

    /// <inheritdoc />
    public async Task<int> SetPasswordHashAsync(
        string userId,
        string passwordHash,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            throw new ArgumentException("userId required.", nameof(userId));
        if (string.IsNullOrWhiteSpace(passwordHash))
            throw new ArgumentException("passwordHash required.", nameof(passwordHash));

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        const string sql = """
            UPDATE dbo.AspNetUsers
            SET PasswordHash = @PasswordHash,
                SecurityStamp = @SecurityStamp
            WHERE Id = @Id
            """;

        return await conn
            .ExecuteAsync(
                new CommandDefinition(
                    sql,
                    new
                    {
                        PasswordHash = passwordHash,
                        SecurityStamp = Guid.NewGuid().ToString("D"),
                        Id = userId,
                    },
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<int> SetLockoutEnabledAsync(
        IReadOnlyList<string> userIds,
        bool enabled,
        CancellationToken cancellationToken = default)
    {
        if (userIds.Count == 0)
        {
            return 0;
        }

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var tx = (SqlTransaction)await conn.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        var affected = 0;
        try
        {
            const string sql = """
                UPDATE dbo.AspNetUsers
                SET LockoutEnabled = @Enabled
                WHERE Id = @Id
                """;
            foreach (var id in userIds.Distinct(StringComparer.Ordinal))
            {
                affected += await conn.ExecuteAsync(
                        sql,
                        new { Enabled = enabled, Id = id },
                        transaction: tx)
                    .ConfigureAwait(false);
            }

            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }

        return affected;
    }

    public async Task SyncHoSoNhanSuAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        // Legacy sync job — same as old app: exec A_TienIch_HoSoNhanSu ''
        await conn.ExecuteAsync(
                "EXEC dbo.A_TienIch_HoSoNhanSu @p",
                new { p = string.Empty },
                commandType: CommandType.Text)
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<RoleOptionDto>> GetRolesAllAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var rows = await conn
            .QueryAsync(
                "sp_HT_Roles_GetAll",
                commandType: CommandType.StoredProcedure)
            .ConfigureAwait(false);
        var list = new List<RoleOptionDto>();
        foreach (var row in rows)
        {
            var d = (IDictionary<string, object>)row;
            var id = GetString(d, "Id", "RoleId", "id") ?? string.Empty;
            var name = GetString(d, "Name", "Ten", "RoleName");
            if (id.Length > 0)
            {
                list.Add(new RoleOptionDto(id, name ?? string.Empty));
            }
        }

        return list;
    }

    public async Task<IReadOnlyList<DonViOptionDto>> GetDonViListAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        // Many DMPortal installs do not ship sp_v2_DonVi_List. Read directly from dbo.DM_DonVi (no schema change).
        // TODO(legacy-db): If your database has sp_v2_DonVi_List (or another list proc), switch back or add options.
        const string sql = """
            SELECT dv.Id,
                   ISNULL(dv.Ma, N'') AS Ma,
                   ISNULL(dv.Ten, N'') AS Ten
            FROM dbo.DM_DonVi AS dv
            ORDER BY dv.Ma;
            """;
        var list = (await conn
                .QueryAsync<DonViOptionDto>(sql, commandType: CommandType.Text)
                .ConfigureAwait(false))
            .ToList();
        return list;
    }

    public async Task<IReadOnlyList<DonViOptionDto>> GetDonViBySpDmDonViGetAllOrderbyMaAoAsync(
        string userName,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("username", userName.Trim());
        var rows = await conn
            .QueryAsync(
                "sp_DM_DonVi_GetAllOrderbyMaAo",
                p,
                commandType: CommandType.StoredProcedure)
            .ConfigureAwait(false);
        var list = new List<DonViOptionDto>();
        foreach (var row in rows)
        {
            var d = (IDictionary<string, object>)row;
            list.Add(MapDonViOption(d));
        }

        return list;
    }

    public async Task<IReadOnlyList<DonViOptionDto>> GetDonViPetrolRetailStoresAsync(
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        const string sql = """
            SELECT dv.Id,
                   ISNULL(dv.Ma, N'') AS Ma,
                   ISNULL(dv.Ten, N'') AS Ten
            FROM dbo.DM_DonVi AS dv
            WHERE dv.CapDonViId = @CapDonViId
            ORDER BY dv.Ma;
            """;
        var list = (await conn
                .QueryAsync<DonViOptionDto>(
                    sql,
                    new { CapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.Text)
                .ConfigureAwait(false))
            .ToList();
        return list;
    }

    public async Task<IReadOnlyList<DonViOptionDto>> GetDonViSoStaffAsync(
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        const string sql = """
            SELECT dv.Id,
                   ISNULL(dv.Ma, N'') AS Ma,
                   ISNULL(dv.Ten, N'') AS Ten
            FROM dbo.DM_DonVi AS dv
            WHERE dv.CapDonViId = @CapDonViId
            ORDER BY dv.Ma;
            """;
        var list = (await conn
                .QueryAsync<DonViOptionDto>(
                    sql,
                    new { CapDonViId = SoStaffUnitConstants.CapDonViId },
                    commandType: CommandType.Text)
                .ConfigureAwait(false))
            .ToList();
        return list;
    }

    private static DonViOptionDto MapDonViOption(IDictionary<string, object> d)
    {
        var id = GetInt(d, "Id", "DonViId", "DV_ID", "IdDonVi") ?? 0;
        var ma = GetString(d, "Ma", "MA", "MaDonVi", "MaAo") ?? string.Empty;
        var ten = GetString(d, "Ten", "TEN", "TenDonVi", "TenDayDu", "TenDV") ?? string.Empty;
        return new DonViOptionDto(id, ma, ten);
    }

    public async Task ReplaceUserRolesAsync(
        string userId,
        IReadOnlyList<string> roleIds,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var tx = (SqlTransaction)await conn.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            // Prefer legacy SPs in production; Identity tables are the ASP.NET default for JWT / roles.
            await conn.ExecuteAsync(
                    "DELETE FROM dbo.AspNetUserRoles WHERE UserId = @UserId",
                    new { UserId = userId },
                    transaction: tx)
                .ConfigureAwait(false);

            foreach (var roleId in roleIds.Distinct(StringComparer.Ordinal))
            {
                var roleIdSql = LegacyAspNetRolesRoleIdFormatter.FormatForAspNetTables(roleId);
                if (roleIdSql.Length == 0)
                {
                    continue;
                }

                await conn.ExecuteAsync(
                        "INSERT INTO dbo.AspNetUserRoles (UserId, RoleId) VALUES (@UserId, @RoleId)",
                        new { UserId = userId, RoleId = roleIdSql },
                        transaction: tx)
                    .ConfigureAwait(false);
            }

            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }
    }

    public async Task ReplaceUserDonVisAsync(
        string userId,
        IReadOnlyList<int> donViIds,
        CancellationToken cancellationToken = default)
    {
        if (donViIds.Count == 0)
        {
            return;
        }

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        foreach (var donViId in donViIds.Distinct())
        {
            var p = new DynamicParameters();
            p.Add("UserId", userId);
            p.Add("DonViId", donViId);
            // TODO(legacy-db): confirm sp_HT_Users_DonVi_AddOrUpdate parameter names / delete-before-insert strategy.
            await conn.ExecuteAsync(
                    "sp_HT_Users_DonVi_AddOrUpdate",
                    p,
                    commandType: CommandType.StoredProcedure)
                .ConfigureAwait(false);
        }
    }

    private static UserListItemDto MapListRow(IDictionary<string, object> d)
    {
        var id = GetString(d, "Id", "UserId", "id") ?? string.Empty;
        var userName = GetString(d, "UserName", "userName", "TenDangNhap") ?? string.Empty;
        var displayName = GetString(d, "DisplayName", "displayName", "HoTen");
        var loai = GetInt(d, "Loai", "loai");
        var donViId = GetInt(d, "DonViId", "donViId", "IdDonVi");
        var donViTen = GetString(d, "DonViDisplayName", "TenDonVi", "DonVi", "TenDonViText");
        var locked = GetBool(d, "IsLocked", "Khoa", "LockoutEnabled");
        var loaiLabel = AdminPortalLoaiRoleMapper.MapRole(loai);
        return new UserListItemDto(
            id,
            userName,
            displayName,
            loai,
            loaiLabel,
            donViId,
            donViTen,
            locked ?? false);
    }

    private static UserDetailDto MapDetail(
        IDictionary<string, object> d,
        IReadOnlyList<UserRoleAssignmentDto> roles,
        IReadOnlyList<UserDonViAssignmentDto> donVis)
    {
        var id = GetString(d, "Id", "UserId") ?? string.Empty;
        var userName = GetString(d, "UserName", "TenDangNhap") ?? string.Empty;
        var displayName = GetString(d, "DisplayName", "HoTen");
        var fullName = GetString(d, "FullName", "TenDayDu");
        var email = GetString(d, "Email");
        var phone = GetString(d, "Phone", "PhoneNumber", "DienThoai");
        var address = GetString(d, "Address", "DiaChi");
        var description = GetString(d, "Description", "MoTa");
        var locked = GetBool(d, "IsLocked", "LockoutEnabled", "Khoa") ?? false;
        var donViId = GetInt(d, "DonViId", "IdDonVi");
        var donViTen = GetString(d, "DonViDisplayName", "TenDonVi", "DonVi");
        var loai = GetInt(d, "Loai");
        var loaiLabel = AdminPortalLoaiRoleMapper.MapRole(loai);
        return new UserDetailDto(
            id,
            userName,
            fullName,
            displayName,
            email,
            phone,
            address,
            description,
            locked,
            donViId,
            donViTen,
            loai,
            loaiLabel,
            roles,
            donVis);
    }

    private static UserRoleAssignmentDto MapRoleRow(IDictionary<string, object> d)
    {
        var roleId = GetString(d, "RoleId", "Id", "roleId") ?? string.Empty;
        var name = GetString(d, "RoleName", "Name", "Ten");
        return new UserRoleAssignmentDto(roleId, name);
    }

    private static UserDonViAssignmentDto MapDonViRow(IDictionary<string, object> d)
    {
        var id = GetInt(d, "DonViId", "Id") ?? 0;
        var ma = GetString(d, "Ma");
        var ten = GetString(d, "Ten", "TenDonVi");
        return new UserDonViAssignmentDto(id, ma, ten);
    }

    private static string? GetString(IDictionary<string, object> d, params string[] keys)
    {
        foreach (var key in keys)
        {
            foreach (var kv in d)
            {
                if (!string.Equals(kv.Key, key, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (kv.Value is null or DBNull)
                {
                    return null;
                }

                return Convert.ToString(kv.Value, CultureInfo.InvariantCulture);
            }
        }

        return null;
    }

    private static int? GetInt(IDictionary<string, object> d, params string[] keys)
    {
        foreach (var key in keys)
        {
            foreach (var kv in d)
            {
                if (!string.Equals(kv.Key, key, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (kv.Value is null or DBNull)
                {
                    return null;
                }

                if (kv.Value is int i)
                {
                    return i;
                }

                if (kv.Value is long l)
                {
                    return (int)l;
                }

                if (kv.Value is short s)
                {
                    return s;
                }

                if (int.TryParse(Convert.ToString(kv.Value, CultureInfo.InvariantCulture), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed))
                {
                    return parsed;
                }
            }
        }

        return null;
    }

    private static bool? GetBool(IDictionary<string, object> d, params string[] keys)
    {
        foreach (var key in keys)
        {
            foreach (var kv in d)
            {
                if (!string.Equals(kv.Key, key, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (kv.Value is null or DBNull)
                {
                    return null;
                }

                if (kv.Value is bool b)
                {
                    return b;
                }

                if (kv.Value is byte by)
                {
                    return by != 0;
                }

                if (int.TryParse(Convert.ToString(kv.Value, CultureInfo.InvariantCulture), NumberStyles.Integer, CultureInfo.InvariantCulture, out var n))
                {
                    return n != 0;
                }

                if (bool.TryParse(Convert.ToString(kv.Value, CultureInfo.InvariantCulture), out var pb))
                {
                    return pb;
                }
            }
        }

        return null;
    }
}

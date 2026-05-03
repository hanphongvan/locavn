using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Auth.Registration.Contracts;
using Httm.XangDau.Api.Shared.Legacy;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Auth.Registration.Persistence;

/// <inheritdoc cref="IUserRegistrationWriteRepository" />
/// <remarks>
/// <para><c>sp_HT_Users_GetByUserName</c> filters <c>LockoutEnabled = 0</c> (login lookup), so username uniqueness uses a direct
/// <c>AspNetUsers</c> query instead of that proc.</para>
/// <para>Legacy SP signatures (production): <c>sp_HT_User_Roles_AddOrUpdate</c> (<c>@UserId</c>, <c>@RoleId</c> as <c>uniqueidentifier</c>);
/// <c>sp_HT_Users_DonVi_AddOrUpdate</c> (<c>@Id</c>, <c>@UserId</c>, <c>@Don_Vi_Id</c>, audit columns).</para>
/// <para><c>AspNetUsers</c> insert: extend with extra columns if your DB requires them.</para>
/// </remarks>
public sealed class UserRegistrationWriteRepository(IConfiguration configuration) : IUserRegistrationWriteRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<bool> UserNameExistsAsync(string userName, CancellationToken cancellationToken = default)
    {
        var u = userName.Trim();
        if (u.Length == 0)
        {
            return false;
        }

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        // sp_HT_Users_GetByUserName excludes locked users (LockoutEnabled=1); registration must reject any duplicate UserName.
        const string sql = "SELECT COUNT(1) FROM dbo.AspNetUsers WHERE UserName = @UserName;";
        var n = await conn
            .ExecuteScalarAsync<int>(
                new CommandDefinition(sql, new { UserName = u }, cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return n > 0;
    }

    /// <inheritdoc />
    public async Task InsertUserWithRelationsAsync(
        string userId,
        RegisterUserRequest request,
        string passwordHash,
        string securityStamp,
        IReadOnlyList<string> checkedRoleIds,
        IReadOnlyList<int> checkedDonViIds,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var tx = (SqlTransaction)await conn.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await InsertAspNetUserRowAsync(conn, tx, userId, request, passwordHash, securityStamp, cancellationToken)
                .ConfigureAwait(false);

            var userIdGuid = ParseUserIdGuid(userId);
            foreach (var roleId in checkedRoleIds.Distinct(StringComparer.Ordinal))
            {
                var roleIdSql = LegacyAspNetRolesRoleIdFormatter.FormatForAspNetTables(roleId);
                if (roleIdSql.Length == 0 || !Guid.TryParse(roleIdSql, out var roleGuid))
                {
                    continue;
                }

                // Legacy proc inserts AspNetUserRoles when missing; parameters are uniqueidentifier.
                await ExecuteSpHtUserRolesAddOrUpdateAsync(conn, tx, userIdGuid, roleGuid, cancellationToken).ConfigureAwait(false);
            }

            foreach (var donViId in checkedDonViIds.Distinct())
            {
                await ExecuteSpHtUsersDonViAddOrUpdateAsync(conn, tx, userIdGuid, donViId, cancellationToken).ConfigureAwait(false);
            }

            if (request.Loai == 3 && request.DonViId is { } mainDv && mainDv > 0)
            {
                await conn
                    .ExecuteAsync(
                        new CommandDefinition(
                            "DELETE FROM dbo.HT_Users_DonVi WHERE UserId = @UserId",
                            new { UserId = userIdGuid },
                            transaction: tx,
                            cancellationToken: cancellationToken))
                    .ConfigureAwait(false);
                await ExecuteSpHtUsersDonViAddOrUpdateAsync(conn, tx, userIdGuid, mainDv, cancellationToken).ConfigureAwait(false);
            }

            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }
    }

    private static async Task InsertAspNetUserRowAsync(
        SqlConnection conn,
        SqlTransaction tx,
        string userId,
        RegisterUserRequest request,
        string passwordHash,
        string securityStamp,
        CancellationToken cancellationToken)
    {
        var email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
        var phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();
        var displayName = request.DisplayName.Trim();
        var userName = request.UserName.Trim();
        var loai = request.Loai ?? 5;
        var donViId = request.DonViId;
        var lockoutEnabled = request.IsActived;

        await conn.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.AspNetUsers (
                        Id,
                        UserName,
                        Email,
                        EmailConfirmed,
                        PasswordHash,
                        SecurityStamp,
                        PhoneNumber,
                        PhoneNumberConfirmed,
                        TwoFactorEnabled,
                        LockoutEndDateUtc,
                        LockoutEnabled,
                        AccessFailedCount,
                        DisplayName,
                        Job,
                        Department,
                        ToChucId,
                        PermissionToChucId,
                        IsADUser,
                        DonViId,
                        Loai,
                        NgonNguId,
                        CanBoId,
                        Picture,
                        PasswordApp
                    )
                    VALUES (
                        @Id,
                        @UserName,
                        @Email,
                        @EmailConfirmed,
                        @PasswordHash,
                        @SecurityStamp,
                        @PhoneNumber,
                        @PhoneNumberConfirmed,
                        @TwoFactorEnabled,
                        @LockoutEndDateUtc,
                        @LockoutEnabled,
                        @AccessFailedCount,
                        @DisplayName,
                        @Job,
                        @Department,
                        @ToChucId,
                        @PermissionToChucId,
                        @IsADUser,
                        @DonViId,
                        @Loai,
                        @NgonNguId,
                        @CanBoId,
                        @Picture,
                        @PasswordApp
                    )
                    """,
                    new
                    {
                        Id = userId,
                        UserName = userName,
                        Email = email,
                        EmailConfirmed = false,
                        PasswordHash = passwordHash,
                        SecurityStamp = securityStamp,
                        PhoneNumber = phone,
                        PhoneNumberConfirmed = false,
                        TwoFactorEnabled = false,
                        LockoutEndDateUtc = (DateTime?)null,
                        LockoutEnabled = lockoutEnabled,
                        AccessFailedCount = 0,
                        DisplayName = displayName,
                        Job = (string?)null,
                        Department = (string?)null,
                        ToChucId = Guid.Empty,
                        PermissionToChucId = Guid.Empty,
                        IsADUser = false,
                        DonViId = donViId,
                        Loai = loai,
                        NgonNguId = 1,
                        CanBoId = (int?)null,
                        Picture = (string?)null,
                        PasswordApp = (string?)null,
                    },
                    transaction: tx,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    private static async Task ExecuteSpHtUserRolesAddOrUpdateAsync(
        SqlConnection conn,
        SqlTransaction tx,
        Guid userId,
        Guid roleId,
        CancellationToken cancellationToken)
    {
        var p = new DynamicParameters();
        p.Add("UserId", userId);
        p.Add("RoleId", roleId);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_HT_User_Roles_AddOrUpdate",
                    p,
                    transaction: tx,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    private static async Task ExecuteSpHtUsersDonViAddOrUpdateAsync(
        SqlConnection conn,
        SqlTransaction tx,
        Guid userId,
        int donViId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var p = new DynamicParameters();
        p.Add("Id", Guid.NewGuid());
        p.Add("UserId", userId);
        p.Add("Don_Vi_Id", donViId);
        p.Add("Created", now);
        p.Add("CreatedBy", (string?)null);
        p.Add("Modified", now);
        p.Add("ModifiedBy", (string?)null);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_HT_Users_DonVi_AddOrUpdate",
                    p,
                    transaction: tx,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    private static Guid ParseUserIdGuid(string userId)
    {
        if (!Guid.TryParse(userId, out var g))
        {
            throw new InvalidOperationException("UserId must be a parseable GUID for legacy stored procedures.");
        }

        return g;
    }
}

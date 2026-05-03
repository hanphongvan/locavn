using System.Net.Mail;
using Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;
using Httm.XangDau.Api.Features.Admin.UserManagement.Persistence;
using Httm.XangDau.Api.Features.Auth.Registration.Contracts;
using Httm.XangDau.Api.Features.Auth.Registration.Persistence;
using Httm.XangDau.Api.Shared.Legacy;

namespace Httm.XangDau.Api.Features.Auth.Registration.Services;

public sealed class UserRegistrationService(
    IUserRegistrationWriteRepository write,
    ILegacyHtUserRepository legacyUsers) : IUserRegistrationService
{
    private const int DefaultLoai = 5;

    /// <inheritdoc />
    public async Task<IReadOnlyList<RegisterRoleOptionDto>> GetRolesAsync(CancellationToken cancellationToken = default)
    {
        var rows = await legacyUsers.GetRolesAllAsync(cancellationToken).ConfigureAwait(false);
        return rows
            .Select(r => new RegisterRoleOptionDto { Id = r.Id, Name = r.Name })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RegisterDonViOptionDto>> GetDonVisAsync(CancellationToken cancellationToken = default)
    {
        var rows = await legacyUsers.GetDonViListAsync(cancellationToken).ConfigureAwait(false);
        return rows
            .Select(d => new RegisterDonViOptionDto { Id = d.Id, Ma = d.Ma, Name = d.Ten })
            .ToList();
    }

    /// <inheritdoc />
    public Task<bool> IsUserNameTakenAsync(string userName, CancellationToken cancellationToken = default) =>
        write.UserNameExistsAsync(userName, cancellationToken);

    /// <inheritdoc />
    public async Task<(RegisterUserResponse? Result, string? Error)> RegisterAsync(
        RegisterUserRequest request,
        CancellationToken cancellationToken = default)
    {
        var err = Validate(request);
        if (err is not null)
        {
            return (null, err);
        }

        var userName = request.UserName.Trim();
        if (await write.UserNameExistsAsync(userName, cancellationToken).ConfigureAwait(false))
        {
            return (null, "Tên đã tồn tại.");
        }

        var loai = request.Loai ?? DefaultLoai;
        request.Loai = loai;

        if ((loai == 3 || loai == 4) && (request.DonViId is null or <= 0))
        {
            return (null, "Đơn vị (DonViId) là bắt buộc với loại tài khoản này.");
        }

        var checkedRoleRows = request.Roles.Where(r => r.Checked).ToList();
        if (checkedRoleRows.Exists(r => string.IsNullOrWhiteSpace(r.Id)))
        {
            return (null, "Vai trò không hợp lệ.");
        }

        var userId = Guid.NewGuid().ToString("D");
        var passwordHash = LegacyAspNetIdentityV2PasswordHasher.HashPassword(request.Password);
        var securityStamp = Guid.NewGuid().ToString("D");

        var checkedRoleIds = checkedRoleRows
            .Select(r => LegacyAspNetRolesRoleIdFormatter.FormatForAspNetTables(r.Id))
            .Distinct(StringComparer.Ordinal)
            .ToList();
        var checkedDonViIds = request.DVs.Where(d => d.Checked).Select(d => d.Id).ToList();

        await write
            .InsertUserWithRelationsAsync(userId, request, passwordHash, securityStamp, checkedRoleIds, checkedDonViIds, cancellationToken)
            .ConfigureAwait(false);

        return (new RegisterUserResponse { UserId = userId, UserName = userName }, null);
    }

    private static string? Validate(RegisterUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserName))
        {
            return "Tên đăng nhập là bắt buộc.";
        }

        if (string.IsNullOrWhiteSpace(request.DisplayName))
        {
            return "Tên hiển thị là bắt buộc.";
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return "Mật khẩu là bắt buộc.";
        }

        if (request.Password.Length < 6)
        {
            return "Mật khẩu phải có ít nhất 6 ký tự.";
        }

        if (!string.Equals(request.Password, request.ConfirmPassword, StringComparison.Ordinal))
        {
            return "Mật khẩu xác nhận không khớp.";
        }

        if (!string.IsNullOrWhiteSpace(request.Email) && !IsValidEmail(request.Email.Trim()))
        {
            return "Email không hợp lệ.";
        }

        return null;
    }

    private static bool IsValidEmail(string email)
    {
        try
        {
            _ = new MailAddress(email);
            return true;
        }
        catch
        {
            return false;
        }
    }
}

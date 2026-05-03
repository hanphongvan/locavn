using Httm.XangDau.Api.Features.Auth.Registration;
using Httm.XangDau.Api.Features.Auth.Registration.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Auth.Registration.Services;

/// <summary>
/// Đổi mật khẩu portal: kiểm tra mật khẩu hiện tại giống <see cref="Httm.XangDau.Api.Shared.Security.OAuth.ApplicationOAuthProvider"/>,
/// ghi <c>PasswordHash</c> bằng <see cref="LegacyAspNetIdentityV2PasswordHasher"/> như <see cref="UserRegistrationService"/>.
/// </summary>
public sealed class ChangePasswordService(
    DmpPortalDbContext db,
    IPasswordHasher<AspNetUser> passwordHasher) : IChangePasswordService
{
    /// <inheritdoc />
    public async Task<(ChangePasswordResponse? Result, string? Error)> ChangeAsync(
        string userId,
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            return (null, "Thiếu thông tin người dùng.");

        if (string.IsNullOrWhiteSpace(request.CurrentPassword))
            return (null, "Nhập mật khẩu hiện tại.");

        var err = PortalPasswordRules.ValidateNewPasswordPair(
            request.NewPassword,
            request.ConfirmPassword,
            request.CurrentPassword);
        if (err is not null)
            return (null, err);

        var tracked = await db.AspNetUsers
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken)
            .ConfigureAwait(false);

        if (tracked is null)
            return (null, "Không tìm thấy tài khoản.");

        if (tracked.LockoutEnabled
            && tracked.LockoutEndDateUtc is { } lockoutEnd
            && lockoutEnd > DateTime.UtcNow)
            return (null, "Tài khoản đang bị khóa. Vui lòng thử lại sau.");

        if (string.IsNullOrEmpty(tracked.PasswordHash))
            return (null, "Tài khoản không hỗ trợ đổi mật khẩu theo cách này.");

        var current = request.CurrentPassword;
        var verification = LegacyAspNetIdentityV2PasswordHasher.VerifyPassword(tracked.PasswordHash, current)
            ? PasswordVerificationResult.Success
            : passwordHasher.VerifyHashedPassword(tracked, tracked.PasswordHash, current);

        if (verification == PasswordVerificationResult.Failed)
            return (null, "Mật khẩu hiện tại không đúng.");

        tracked.PasswordHash = LegacyAspNetIdentityV2PasswordHasher.HashPassword(request.NewPassword);
        tracked.SecurityStamp = Guid.NewGuid().ToString("D");
        tracked.AccessFailedCount = 0;
        tracked.LockoutEndDateUtc = null;

        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return (new ChangePasswordResponse { Success = true, Message = "Đã đổi mật khẩu." }, null);
    }
}

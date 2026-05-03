using System.Data;
using Httm.XangDau.Api.Features.Auth.Registration;
using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

/// <summary>
/// Đặt lại mật khẩu qua token email. Sau khi token hợp lệ, cập nhật <c>PasswordHash</c> giống
/// <see cref="Httm.XangDau.Api.Features.Auth.Registration.Services.ChangePasswordService"/> và
/// <see cref="LegacyAspNetIdentityV2PasswordHasher"/> để tương thích DB legacy.
/// </summary>
public sealed class ResetPasswordFromTokenService(
    DmpPortalDbContext db,
    IPasswordHasher<AspNetUser> passwordHasher,
    ILogger<ResetPasswordFromTokenService> logger) : IResetPasswordFromTokenService
{
    /// <inheritdoc />
    public async Task<ResetPasswordResult> TryResetAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        var raw = request.Token?.Trim() ?? string.Empty;
        if (string.IsNullOrEmpty(raw))
            return ResetPasswordResult.TokenInvalid();

        var hash = PasswordResetTokenCrypto.HashRawToken(raw);

        await using var tx = await db.Database
            .BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken)
            .ConfigureAwait(false);

        try
        {
            var now = DateTime.UtcNow;
            var row = await db.PasswordResetTokens
                .Where(t => t.TokenHash == hash && t.UsedAt == null && t.ExpiresAt > now)
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false);

            if (row is null)
            {
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                return ResetPasswordResult.TokenInvalid();
            }

            var pwdErr = PortalPasswordRules.ValidateNewPasswordPair(
                request.NewPassword,
                request.ConfirmPassword,
                currentPasswordPlain: null);
            if (pwdErr is not null)
            {
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                return ResetPasswordResult.PasswordRuleViolation(pwdErr);
            }

            var newPw = request.NewPassword!;

            var user = await db.AspNetUsers
                .FirstOrDefaultAsync(u => u.Id == row.UserId, cancellationToken)
                .ConfigureAwait(false);

            if (user is null || string.IsNullOrEmpty(user.PasswordHash))
            {
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                return ResetPasswordResult.TokenInvalid();
            }

            if (LegacyAspNetIdentityV2PasswordHasher.VerifyPassword(user.PasswordHash, newPw)
                || passwordHasher.VerifyHashedPassword(user, user.PasswordHash, newPw) != PasswordVerificationResult.Failed)
            {
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                return ResetPasswordResult.PasswordRuleViolation("Mật khẩu mới phải khác mật khẩu hiện tại.");
            }

            // Giữ định dạng hash legacy (ASP.NET Identity v2-compatible) như ChangePassword — không đổi cách lưu DB.
            user.PasswordHash = LegacyAspNetIdentityV2PasswordHasher.HashPassword(newPw);
            user.SecurityStamp = Guid.NewGuid().ToString("D");
            user.AccessFailedCount = 0;
            user.LockoutEndDateUtc = null;

            row.UsedAt = now;

            await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);

            logger.LogInformation("Password reset completed for user id {UserId}.", user.Id);
            return ResetPasswordResult.Ok();
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }
    }
}

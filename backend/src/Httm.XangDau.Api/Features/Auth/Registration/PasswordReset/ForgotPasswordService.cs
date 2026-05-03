using System.Net.Mail;
using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public sealed class ForgotPasswordService(
    DmpPortalDbContext db,
    IOptions<PasswordResetOptions> resetOptions,
    IPasswordResetEmailSender emailSender,
    ILogger<ForgotPasswordService> logger) : IForgotPasswordService
{
    private static readonly TimeSpan TokenLifetime = TimeSpan.FromMinutes(30);

    /// <inheritdoc />
    public async Task<ForgotPasswordResponse> ProcessAsync(
        string email,
        string? createdIp,
        string? userAgent,
        CancellationToken cancellationToken = default)
    {
        var uniform = new ForgotPasswordResponse();

        var trimmed = email.Trim();
        var domain = EmailDomain(trimmed);
        logger.LogInformation(
            "Forgot password request received. EmailDomain={EmailDomain}, RemoteIp={RemoteIp}",
            domain ?? "(none)",
            createdIp ?? "(unknown)");

        if (!IsPlausibleEmail(trimmed))
            return uniform;

        var lowered = trimmed.ToLowerInvariant();
        var user = await db.AspNetUsers
            .AsNoTracking()
            .FirstOrDefaultAsync(
                u => u.Email != null && u.Email.ToLower() == lowered,
                cancellationToken)
            .ConfigureAwait(false);

        if (user is null)
            return uniform;

        if (string.IsNullOrEmpty(user.PasswordHash))
            return uniform;

        if (user.LockoutEnabled
            && user.LockoutEndDateUtc is { } lockoutEnd
            && lockoutEnd > DateTime.UtcNow)
            return uniform;

        var rawToken = PasswordResetTokenCrypto.GenerateRawToken();
        var tokenHash = PasswordResetTokenCrypto.HashRawToken(rawToken);

        var now = DateTime.UtcNow;
        var entity = new PasswordResetToken
        {
            UserId = user.Id,
            TokenHash = tokenHash,
            ExpiresAt = now.Add(TokenLifetime),
            UsedAt = null,
            CreatedAt = now,
            CreatedIp = Truncate(createdIp, 50),
            UserAgent = Truncate(userAgent, 500),
        };

        db.PasswordResetTokens.Add(entity);
        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        var baseUrl = resetOptions.Value.WebResetPasswordBaseUrl.TrimEnd('/');
        var resetLink = $"{baseUrl}?token={Uri.EscapeDataString(rawToken)}";

        try
        {
            await emailSender
                .SendPasswordResetLinkAsync(user.Email ?? trimmed, resetLink, cancellationToken)
                .ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send password reset email for user id {UserId}.", user.Id);
        }

        return uniform;
    }

    private static string? EmailDomain(string email)
    {
        var i = email.LastIndexOf('@');
        return i > 0 && i < email.Length - 1 ? email[(i + 1)..] : null;
    }

    private static bool IsPlausibleEmail(string s)
    {
        if (string.IsNullOrWhiteSpace(s) || s.Length > 256)
            return false;

        var at = s.IndexOf('@');
        if (at <= 0 || at == s.Length - 1)
            return false;

        if (s.IndexOf('@', at + 1) >= 0)
            return false;

        try
        {
            _ = new MailAddress(s);
        }
        catch
        {
            return false;
        }

        return true;
    }

    private static string? Truncate(string? s, int maxLen)
    {
        if (string.IsNullOrEmpty(s))
            return null;

        return s.Length <= maxLen ? s : s[..maxLen];
    }
}

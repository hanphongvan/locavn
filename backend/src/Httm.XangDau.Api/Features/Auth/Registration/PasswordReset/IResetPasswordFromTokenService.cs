using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public interface IResetPasswordFromTokenService
{
    Task<ResetPasswordResult> TryResetAsync(ResetPasswordRequest request, CancellationToken cancellationToken = default);
}

/// <summary>Kết quả đặt lại mật khẩu (message hiển thị cho client).</summary>
public sealed class ResetPasswordResult
{
    private ResetPasswordResult(bool success, string message)
    {
        Success = success;
        Message = message;
    }

    public bool Success { get; }
    public string Message { get; }

    public static ResetPasswordResult Ok() =>
        new(true, PasswordResetMessages.ResetPasswordSuccess);

    public static ResetPasswordResult TokenInvalid() =>
        new(false, PasswordResetMessages.ResetPasswordInvalidOrExpired);

    public static ResetPasswordResult PasswordRuleViolation(string message) =>
        new(false, message);
}

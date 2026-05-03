namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public interface IPasswordResetEmailSender
{
    /// <summary>Gửi email đặt lại mật khẩu (không chứa mật khẩu). Không ném nếu SMTP tắt — service gọi log.</summary>
    Task SendPasswordResetLinkAsync(string toEmail, string resetLink, CancellationToken cancellationToken = default);
}

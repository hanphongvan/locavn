namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public sealed class PasswordResetOptions
{
    public const string SectionName = "PasswordReset";

    /// <summary>URL trang đặt lại mật khẩu (không kèm query), ví dụ <c>https://quanhtoi.dms.gov.vn/reset-password</c>.</summary>
    public string WebResetPasswordBaseUrl { get; set; } = "https://quanhtoi.dms.gov.vn/reset-password";
}

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

/// <summary>Thông điệp cố định cho luồng quên / đặt lại mật khẩu (LocaVN).</summary>
public static class PasswordResetMessages
{
    public const string ForgotPasswordUniformResponse =
        "Nếu email tồn tại trong hệ thống, chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến email của bạn.";

    public const string ResetPasswordSuccess =
        "Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập lại.";

    public const string ResetPasswordInvalidOrExpired =
        "Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.";
}

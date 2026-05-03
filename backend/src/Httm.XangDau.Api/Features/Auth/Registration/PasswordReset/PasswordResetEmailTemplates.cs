namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public static class PasswordResetEmailTemplates
{
    public const string Subject = "Đặt lại mật khẩu LocaVN";

    public static string BuildPlainTextBody(string resetLink) =>
        $"""
        Xin chào,

        Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản LocaVN của bạn.

        Vui lòng bấm vào liên kết dưới đây để đặt lại mật khẩu:
        {resetLink}

        Liên kết này có hiệu lực trong 30 phút và chỉ sử dụng được một lần.

        Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.

        Trân trọng,
        LocaVN
        """;
}

namespace Httm.XangDau.Api.Features.Auth.Registration;

/// <summary>
/// Quy tắc mật khẩu portal (đăng ký / đổi mật khẩu / đặt lại qua email) — giữ một nơi để đồng bộ với app.
/// </summary>
public static class PortalPasswordRules
{
    /// <summary>Kiểm tra cặp mật khẩu mới + xác nhận; tùy chọn so khớp với mật khẩu hiện tại (chuỗi rõ).</summary>
    public static string? ValidateNewPasswordPair(
        string? newPassword,
        string? confirmPassword,
        string? currentPasswordPlain)
    {
        if (string.IsNullOrWhiteSpace(newPassword))
            return "Nhập mật khẩu mới.";

        if (newPassword.Length < 6)
            return "Mật khẩu mới phải có ít nhất 6 ký tự.";

        if (!string.Equals(newPassword, confirmPassword, StringComparison.Ordinal))
            return "Mật khẩu xác nhận không khớp.";

        if (currentPasswordPlain is not null
            && string.Equals(newPassword, currentPasswordPlain, StringComparison.Ordinal))
            return "Mật khẩu mới phải khác mật khẩu hiện tại.";

        return null;
    }
}

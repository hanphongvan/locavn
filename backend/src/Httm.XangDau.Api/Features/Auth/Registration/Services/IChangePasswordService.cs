using Httm.XangDau.Api.Features.Auth.Registration.Contracts;

namespace Httm.XangDau.Api.Features.Auth.Registration.Services;

public interface IChangePasswordService
{
    /// <summary>
    /// Đổi mật khẩu cho user đang đăng nhập (<c>AspNetUsers</c>), đồng bộ hash với đăng ký / đăng nhập legacy.
    /// </summary>
    Task<(ChangePasswordResponse? Result, string? Error)> ChangeAsync(
        string userId,
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default);
}

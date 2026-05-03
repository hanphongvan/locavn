using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public interface IForgotPasswordService
{
    Task<ForgotPasswordResponse> ProcessAsync(
        string email,
        string? createdIp,
        string? userAgent,
        CancellationToken cancellationToken = default);
}

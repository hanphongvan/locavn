using Httm.XangDau.Api.Features.Auth.Registration.Contracts;

namespace Httm.XangDau.Api.Features.Auth.Registration.Services;

public interface IUserRegistrationService
{
    Task<IReadOnlyList<RegisterRoleOptionDto>> GetRolesAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<RegisterDonViOptionDto>> GetDonVisAsync(CancellationToken cancellationToken = default);

    Task<bool> IsUserNameTakenAsync(string userName, CancellationToken cancellationToken = default);

    Task<(RegisterUserResponse? Result, string? Error)> RegisterAsync(RegisterUserRequest request, CancellationToken cancellationToken = default);
}

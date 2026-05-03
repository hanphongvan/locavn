using Httm.XangDau.Api.Features.Auth.Registration.Contracts;

namespace Httm.XangDau.Api.Features.Auth.Registration.Persistence;

/// <summary>Transactional writes for public registration (legacy Identity + HT tables).</summary>
public interface IUserRegistrationWriteRepository
{
    /// <returns><c>true</c> if a row exists for the username.</returns>
    Task<bool> UserNameExistsAsync(string userName, CancellationToken cancellationToken = default);

    /// <summary>Inserts <c>AspNetUsers</c> + role/DV side tables under one transaction.</summary>
    Task InsertUserWithRelationsAsync(
        string userId,
        RegisterUserRequest request,
        string passwordHash,
        string securityStamp,
        IReadOnlyList<string> checkedRoleIds,
        IReadOnlyList<int> checkedDonViIds,
        CancellationToken cancellationToken = default);
}

namespace Httm.XangDau.Api.Shared.Security.Portal;

/// <summary>
/// Current admin API request identity: machine API key (full access) or portal JWT (<c>Loai</c>, <c>DonViId</c> from claims).
/// </summary>
public interface IAdminPortalRequestContext
{
    /// <summary><see langword="true"/> when authenticated with <c>X-Admin-Api-Key</c> — bypass portal row-level rules.</summary>
    bool IsMachineFullAccess { get; }

    /// <summary>ASP.NET Identity user id from JWT when Bearer; <see langword="null"/> for API key.</summary>
    string? UserId { get; }

    /// <summary><c>AspNetUsers.UserName</c> from JWT name claim; <see langword="null"/> for API key.</summary>
    string? UserName { get; }

    /// <summary><c>AspNetUsers.Loai</c> from JWT when Bearer.</summary>
    int? Loai { get; }

    /// <summary><c>AspNetUsers.DonViId</c> from JWT when Bearer.</summary>
    int? DonViId { get; }
}

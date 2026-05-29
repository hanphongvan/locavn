using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.AppVersionPolicy;

/// <summary>Response cho <c>GET /api/app/version-policy?platform=...</c>.</summary>
public sealed record AppVersionPolicyDto(
    string Platform,
    string MinSupported,
    string LatestVersion,
    string? MessageVi,
    string? StoreUrl,
    DateTime UpdatedAt);

/// <summary>
/// Request body cho <c>PUT /api/admin/app/version-policy</c>. Tất cả version theo semver lite
/// "MAJOR.MINOR.PATCH" (không pre-release / build metadata).
/// </summary>
public sealed class AppVersionPolicyUpdateRequest
{
    [Required, RegularExpression("^(android|ios)$", ErrorMessage = "Platform phải là 'android' hoặc 'ios'.")]
    public string Platform { get; set; } = null!;

    [Required, RegularExpression(@"^\d+\.\d+\.\d+$", ErrorMessage = "MinSupported phải đúng dạng MAJOR.MINOR.PATCH.")]
    public string MinSupported { get; set; } = null!;

    [Required, RegularExpression(@"^\d+\.\d+\.\d+$", ErrorMessage = "LatestVersion phải đúng dạng MAJOR.MINOR.PATCH.")]
    public string LatestVersion { get; set; } = null!;

    [MaxLength(500)]
    public string? MessageVi { get; set; }

    [MaxLength(500), Url]
    public string? StoreUrl { get; set; }
}

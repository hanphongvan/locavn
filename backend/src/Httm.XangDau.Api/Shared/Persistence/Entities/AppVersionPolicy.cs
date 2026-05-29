namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>
/// Policy phiên bản app mobile per platform. Mobile splash gọi <c>GET /api/app/version-policy</c>
/// để biết có nên force-update / soft-update không. Admin sửa qua <c>PUT /api/admin/app/version-policy</c>.
/// </summary>
public sealed class AppVersionPolicy
{
    /// <summary>PK: <c>android</c> | <c>ios</c>.</summary>
    public string Platform { get; set; } = null!;

    /// <summary>Phiên bản tối thiểu vẫn được hỗ trợ. Dưới mức này → force-update dialog.</summary>
    public string MinSupported { get; set; } = null!;

    /// <summary>Phiên bản mới nhất. Dưới mức này nhưng &gt;= MinSupported → soft-update dialog.</summary>
    public string LatestVersion { get; set; } = null!;

    /// <summary>Nội dung dialog (tiếng Việt).</summary>
    public string? MessageVi { get; set; }

    /// <summary>Link Play Store / App Store.</summary>
    public string? StoreUrl { get; set; }

    public DateTime UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }
}

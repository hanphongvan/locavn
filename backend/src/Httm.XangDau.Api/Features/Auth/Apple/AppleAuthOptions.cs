namespace Httm.XangDau.Api.Features.Auth.Apple;

/// <summary>
/// Cấu hình verify Apple ID token cho endpoint <c>POST /api/oauth/apple</c>.
/// Đọc từ section <c>AppleAuth</c>.
/// </summary>
public sealed class AppleAuthOptions
{
    public const string SectionName = "AppleAuth";

    /// <summary>
    /// Danh sách Bundle ID / Service ID được chấp nhận làm <c>aud</c> trong Apple ID token.
    /// <list type="bullet">
    ///   <item>iOS app: thường là iOS Bundle ID (vd <c>vn.gov.dms.locavn</c>).</item>
    ///   <item>Web / Android: dùng Service ID đã tạo trên Apple Developer Console.</item>
    /// </list>
    /// Trống → từ chối tất cả token (fail-safe).
    /// </summary>
    public IList<string> Audiences { get; set; } = new List<string>();
}

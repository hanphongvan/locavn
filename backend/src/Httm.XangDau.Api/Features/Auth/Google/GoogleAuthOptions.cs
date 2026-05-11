namespace Httm.XangDau.Api.Features.Auth.Google;

/// <summary>
/// Cấu hình verify Google ID token cho endpoint <c>POST /api/oauth/google</c>.
/// </summary>
public sealed class GoogleAuthOptions
{
    public const string SectionName = "GoogleAuth";

    /// <summary>
    /// Danh sách OAuth Client ID được chấp nhận làm <c>aud</c> claim trong Google ID token.
    /// Thường gồm: Web client ID (server) + Android/iOS client ID nếu mobile không dùng <c>serverClientId</c>.
    /// Bỏ trống → endpoint trả 503/invalid_grant để tránh accept arbitrary token.
    /// </summary>
    public IList<string> AllowedAudiences { get; set; } = new List<string>();
}

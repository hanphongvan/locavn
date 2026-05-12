namespace Httm.XangDau.Api.Features.Auth.Apple.Contracts;

/// <summary>Body của <c>POST /api/oauth/apple</c>.</summary>
public sealed class AppleLoginRequest
{
    /// <summary>Apple ID token (JWT signed by Apple) nhận từ mobile sau khi user authorize.</summary>
    public string? IdToken { get; set; }

    /// <summary>
    /// Tên người dùng — Apple chỉ trả ở LẦN LOGIN ĐẦU TIÊN, không có ở các lần sau.
    /// Mobile gửi kèm để BE lưu displayName khi auto-create user. Null nếu không có.
    /// </summary>
    public AppleFullName? FullName { get; set; }
}

public sealed class AppleFullName
{
    public string? GivenName { get; set; }
    public string? FamilyName { get; set; }
}

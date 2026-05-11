namespace Httm.XangDau.Api.Features.Auth.Google.Contracts;

/// <summary>Body của <c>POST /api/oauth/google</c>.</summary>
public sealed class GoogleLoginRequest
{
    /// <summary>Google ID token nhận được từ mobile sau khi user chọn account.</summary>
    public string? IdToken { get; set; }
}

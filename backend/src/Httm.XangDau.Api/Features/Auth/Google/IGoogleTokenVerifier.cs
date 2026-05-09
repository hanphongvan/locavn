namespace Httm.XangDau.Api.Features.Auth.Google;

public interface IGoogleTokenVerifier
{
    /// <summary>Verify Google ID token (signature + audience + expiry). Trả null nếu invalid hoặc chưa cấu hình audience.</summary>
    Task<GoogleVerifiedIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default);
}

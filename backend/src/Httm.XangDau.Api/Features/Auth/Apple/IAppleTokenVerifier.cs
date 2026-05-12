namespace Httm.XangDau.Api.Features.Auth.Apple;

public interface IAppleTokenVerifier
{
    /// <summary>Verify Apple ID token (RS256 signature + iss + aud + exp). Trả null nếu invalid.</summary>
    Task<AppleVerifiedIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default);
}

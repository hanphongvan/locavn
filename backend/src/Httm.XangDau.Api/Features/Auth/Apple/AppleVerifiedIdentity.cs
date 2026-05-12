namespace Httm.XangDau.Api.Features.Auth.Apple;

/// <summary>Payload đã verify từ Apple ID token (chỉ giữ field cần để map sang AspNetUsers).</summary>
public sealed record AppleVerifiedIdentity(
    string Subject,
    string? Email,
    bool EmailVerified,
    bool IsPrivateEmail);

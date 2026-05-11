namespace Httm.XangDau.Api.Features.Auth.Google;

/// <summary>Payload đã verify từ Google ID token (chỉ giữ field cần để map sang AspNetUsers).</summary>
public sealed record GoogleVerifiedIdentity(
    string Subject,
    string Email,
    bool EmailVerified,
    string? Name,
    string? Picture);

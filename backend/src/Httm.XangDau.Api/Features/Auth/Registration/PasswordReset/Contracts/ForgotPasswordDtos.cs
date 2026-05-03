using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;

/// <summary>Request/response cho <c>POST /api/auth/forgot-password</c>.</summary>
public sealed class ForgotPasswordRequest
{
    public string? Email { get; set; }
}

public sealed class ForgotPasswordResponse
{
    public string Message { get; set; } = PasswordResetMessages.ForgotPasswordUniformResponse;
}

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;

public sealed class ResetPasswordRequest
{
    public string? Token { get; set; }

    public string? NewPassword { get; set; }

    public string? ConfirmPassword { get; set; }
}

public sealed class ResetPasswordMessageResponse
{
    public string Message { get; set; } = "";
}

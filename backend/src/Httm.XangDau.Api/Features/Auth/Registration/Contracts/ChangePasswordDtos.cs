using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.Auth.Registration.Contracts;

public sealed class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required]
    public string NewPassword { get; set; } = string.Empty;

    [Required]
    public string ConfirmPassword { get; set; } = string.Empty;
}

public sealed class ChangePasswordResponse
{
    public bool Success { get; set; }

    public string Message { get; set; } = string.Empty;
}

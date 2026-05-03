using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.Auth.Registration.Contracts;

public sealed class RegisterUserRequest
{
    [Required]
    public string UserName { get; set; } = string.Empty;

    [Required]
    public string DisplayName { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;

    [Required]
    public string ConfirmPassword { get; set; } = string.Empty;

    public string? Email { get; set; }

    public string? Phone { get; set; }

    public string? Address { get; set; }

    /// <summary>Legacy UI field name: maps 1:1 to <c>AspNetUsers.LockoutEnabled</c> (khóa tài khoản = <c>true</c>).</summary>
    public bool IsActived { get; set; }

    /// <summary>Portal user type. New app default: <c>5</c>. Types <c>3</c> and <c>4</c> require <see cref="DonViId"/>.</summary>
    public int? Loai { get; set; }

    public int? DonViId { get; set; }

    public List<RoleSelectionDto> Roles { get; set; } = [];

    public List<DonViSelectionDto> DVs { get; set; } = [];
}

public sealed class RoleSelectionDto
{
    /// <summary>Must match <c>AspNetRoles.Id</c> exactly (same string as <c>GET …/register-user/roles</c>).</summary>
    public string Id { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public bool Checked { get; set; }
}

public sealed class DonViSelectionDto
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public bool Checked { get; set; }
}

public sealed class RegisterUserResponse
{
    public string UserId { get; set; } = string.Empty;

    public string UserName { get; set; } = string.Empty;
}

public sealed class RegisterRoleOptionDto
{
    public string Id { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
}

public sealed class RegisterDonViOptionDto
{
    public int Id { get; set; }

    public string Ma { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
}

public sealed class RegisterUserNameCheckDto
{
    public string UserName { get; set; } = string.Empty;

    public bool Taken { get; set; }
}

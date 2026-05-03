namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>
/// Bảng <c>PasswordResetTokens</c> — token đặt lại mật khẩu (chỉ lưu hash).
/// <c>UserId</c> khớp <see cref="AspNetUser.Id"/> (<c>nvarchar(128)</c> trong DMPPortal, không phải int).
/// </summary>
public sealed class PasswordResetToken
{
    public int Id { get; set; }

    /// <summary>FK → <c>AspNetUsers.Id</c>.</summary>
    public string UserId { get; set; } = null!;

    public string TokenHash { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public DateTime? UsedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public string? CreatedIp { get; set; }

    public string? UserAgent { get; set; }

    public AspNetUser? User { get; set; }
}

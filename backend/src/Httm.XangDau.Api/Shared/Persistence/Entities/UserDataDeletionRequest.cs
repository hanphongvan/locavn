namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>
/// Yêu cầu xoá dữ liệu cá nhân từ ứng dụng (ghi nhận — không xoá ngay tại endpoint).
/// <c>UserId</c> khớp <see cref="AspNetUser.Id"/>.
/// </summary>
public sealed class UserDataDeletionRequest
{
    public int Id { get; set; }

    /// <summary>FK → <c>AspNetUsers.Id</c>.</summary>
    public string UserId { get; set; } = null!;

    public string RequestType { get; set; } = null!;

    public string Scope { get; set; } = null!;

    public string? Note { get; set; }

    /// <summary>Pending, Processing, Completed, Rejected</summary>
    public string Status { get; set; } = null!;

    public DateTime RequestedAt { get; set; }

    public DateTime? ProcessedAt { get; set; }

    public string? ProcessedBy { get; set; }

    public AspNetUser? User { get; set; }
}

namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Góp ý của người dùng về ứng dụng (không gắn với trạm). Có thể gửi ẩn danh.</summary>
public sealed class AppFeedback
{
    public int Id { get; set; }

    /// <summary><c>AspNetUsers.Id</c> khi gửi từ phiên đã đăng nhập; null khi khách gửi ẩn danh.</summary>
    public string? UserId { get; set; }

    public AppFeedbackCategory Category { get; set; }

    public string Content { get; set; } = null!;

    /// <summary>Email liên hệ tùy chọn (để cán bộ phản hồi).</summary>
    public string? ContactEmail { get; set; }

    /// <summary>Số điện thoại liên hệ tùy chọn.</summary>
    public string? ContactPhone { get; set; }

    /// <summary>Phiên bản app gửi kèm (ví dụ <c>1.4.0+42</c>) — bối cảnh xử lý.</summary>
    public string? AppVersion { get; set; }

    /// <summary>Nền tảng gửi: <c>android</c> / <c>ios</c> / <c>web</c>.</summary>
    public string? Platform { get; set; }

    public DateTime CreatedAt { get; set; }

    public AppFeedbackStatus Status { get; set; }

    public ICollection<AppFeedbackImage> Images { get; set; } = new List<AppFeedbackImage>();
}

namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Phân loại góp ý ứng dụng (<c>AppFeedbacks.Category</c>, <c>tinyint</c>).</summary>
public enum AppFeedbackCategory : byte
{
    /// <summary>Báo lỗi.</summary>
    Bug = 0,

    /// <summary>Đề xuất tính năng / cải tiến.</summary>
    Suggestion = 1,

    /// <summary>Khác.</summary>
    Other = 2,
}

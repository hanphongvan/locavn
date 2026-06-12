namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Trạng thái xử lý góp ý (<c>AppFeedbacks.Status</c>, <c>tinyint</c>).</summary>
public enum AppFeedbackStatus : byte
{
    Pending = 0,
    UnderReview = 1,
    Resolved = 2,
}

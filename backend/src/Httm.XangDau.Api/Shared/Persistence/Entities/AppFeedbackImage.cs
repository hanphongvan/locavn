namespace Httm.XangDau.Api.Shared.Persistence.Entities;

public sealed class AppFeedbackImage
{
    public int Id { get; set; }
    public int FeedbackId { get; set; }
    public string ImageUrl { get; set; } = null!;

    public AppFeedback? Feedback { get; set; }
}

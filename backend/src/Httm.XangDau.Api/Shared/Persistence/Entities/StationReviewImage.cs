namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Optional image URL attached to a <see cref="StationReview"/>.</summary>
public sealed class StationReviewImage
{
    public int Id { get; set; }
    public int ReviewId { get; set; }
    public string ImageUrl { get; set; } = null!;

    public StationReview? Review { get; set; }
}

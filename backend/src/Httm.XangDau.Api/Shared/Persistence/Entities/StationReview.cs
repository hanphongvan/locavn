namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Public visitor review for a petrol station (<c>DM_DonVi.Id</c>, <c>CapDonViId = 248</c>). App-owned table.</summary>
public sealed class StationReview
{
    public int Id { get; set; }
    /// <summary><c>AspNetUsers.Id</c> when submitted with JWT; null for anonymous/legacy rows.</summary>
    public string? ReviewerUserId { get; set; }
    public int StationId { get; set; }
    /// <summary>1–5 inclusive.</summary>
    public byte Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }

    public DmDonVi? Station { get; set; }
    public ICollection<StationReviewImage> Images { get; set; } = new List<StationReviewImage>();
}

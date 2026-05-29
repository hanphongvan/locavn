namespace Httm.XangDau.Api.Features.Httm.Contracts;

public sealed class HttmFacilityImageDto
{
    public Guid Id { get; init; }
    public Guid FacilityId { get; init; }
    public string ImageUrl { get; init; } = string.Empty;
    public string ImageType { get; init; } = string.Empty;
    public string? Caption { get; init; }
    public DateOnly? TakenDate { get; init; }
    public short SortOrder { get; init; }
    public string? UploadedBy { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
}

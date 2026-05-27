namespace Httm.XangDau.Api.Features.Httm.Contracts;

public sealed class HttmCatalogItemDto
{
    public Guid Id { get; init; }
    public string Type { get; init; } = string.Empty;
    public string Code { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? NameEn { get; init; }
    public string? ParentCode { get; init; }
    public short SortOrder { get; init; }
    public bool IsActive { get; init; }
    /// <summary>JSON object từ cột <c>Metadata</c>.</summary>
    public string? Metadata { get; init; }
}

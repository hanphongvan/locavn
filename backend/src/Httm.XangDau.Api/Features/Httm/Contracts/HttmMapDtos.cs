using System.Text.Json.Serialization;

namespace Httm.XangDau.Api.Features.Httm.Contracts;

/// <summary>GeoJSON Point geometry (<c>coordinates</c>: [lng, lat]).</summary>
public sealed class HttmMapPointGeometryDto
{
    public string Type { get; init; } = "Point";

    /// <summary>Kinh độ, vĩ độ (RFC 7946).</summary>
    public IReadOnlyList<double> Coordinates { get; init; } = Array.Empty<double>();
}

/// <summary>GeoJSON Feature cho một cơ sở trên bản đồ.</summary>
public sealed class HttmMapFeatureDto
{
    public string Type { get; init; } = "Feature";

    /// <summary>GeoJSON Feature <c>id</c> (RFC 7946).</summary>
    [JsonPropertyName("id")]
    public Guid Id { get; init; }

    public HttmMapPointGeometryDto Geometry { get; init; } = null!;

    public HttmMapFeaturePropertiesDto Properties { get; init; } = null!;
}

/// <summary>Thuộc tính hiển thị popup / tooltip.</summary>
public sealed class HttmMapFeaturePropertiesDto
{
    public string Name { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string ProvinceCode { get; init; } = string.Empty;
    public string? AddressDetail { get; init; }
    public decimal? FloorArea { get; init; }
    public int? StallCount { get; init; }
}

/// <summary>GeoJSON FeatureCollection trả về từ <c>GET /api/httm/map-data</c>.</summary>
public sealed class HttmMapFeatureCollectionResponse
{
    public string Type { get; init; } = "FeatureCollection";

    public IReadOnlyList<HttmMapFeatureDto> Features { get; init; } = Array.Empty<HttmMapFeatureDto>();
}

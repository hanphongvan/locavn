namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary>Row 1 (station info) từ <c>dbo.sp_Api_StationDetail_GetById_V2</c>.</summary>
public sealed class StationDetailV2InfoSqlRow
{
    public int StationId { get; init; }
    public string StationCode { get; init; } = null!;
    public string StationName { get; init; } = null!;
    public string? Phone { get; init; }
    public string? Email { get; init; }
    public string? AddressLine { get; init; }
    public string? LicenseNumber { get; init; }
    public DateTime? LicenseDate { get; init; }
    public DateTime? LicenseExpiryDate { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
    public string? ProvinceCode { get; init; }
    public string? ProvinceName { get; init; }
    public string? WardCode { get; init; }
    public string? WardName { get; init; }
    public int? DistrictId { get; init; }
    public bool? IsActive { get; init; }
    public TimeSpan? OpenTime { get; init; }
    public TimeSpan? CloseTime { get; init; }
    public int? ParentDonViId { get; init; }
}

/// <summary>Row 2 (price list) từ <c>dbo.sp_Api_StationDetail_GetById_V2</c>.</summary>
public sealed class StationDetailV2PriceSqlRow
{
    public string ServiceCode { get; init; } = null!;
    public string DisplayName { get; init; } = null!;
    public decimal? Price { get; init; }
    public int SortOrder { get; init; }
}

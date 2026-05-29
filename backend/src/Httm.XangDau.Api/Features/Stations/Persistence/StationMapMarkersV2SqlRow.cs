namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary>
/// Row from result set 2 of <c>dbo.sp_Api_StationMap_ListPaged_V2</c>.
/// Prices đến trực tiếp từ <c>StationStoreServices.Price</c> (ServiceCode khớp <c>FuelProducts.Code</c>),
/// không cần call <c>fuelReporting</c> snapshot riêng như V1.
/// </summary>
public sealed class StationMapMarkersV2SqlRow
{
    public int StationId { get; init; }
    public string StationName { get; init; } = null!;
    public double Latitude { get; init; }
    public double Longitude { get; init; }
    public string? ShortAddress { get; init; }
    public bool? TrangThai { get; init; }
    public TimeSpan? OpenTime { get; init; }
    public TimeSpan? CloseTime { get; init; }
    public decimal? PriceRon95 { get; init; }
    public decimal? PriceDiesel { get; init; }
    public decimal? PriceForSelectedFuel { get; init; }

    /// <summary>
    /// Comma-separated <c>StationStoreServices.ServiceCode</c> (active) — embed trong SP
    /// để client không phải batch-query <c>WHERE DonViId IN(@batch1..@batch1000)</c> riêng.
    /// </summary>
    public string? Fuels { get; init; }

    /// <summary><c>DM_DonVi.CapTrenId</c> — đầu mối. Embed trong SP để bỏ batch query riêng.</summary>
    public int? ParentDonViId { get; init; }

    /// <summary><c>1</c> = có row <c>StationOperatingHours</c> cho hôm nay; <c>0</c> = không.</summary>
    public bool? HasTodayHours { get; init; }

    public TimeSpan? TodayOpensAt { get; init; }
    public TimeSpan? TodayClosesAt { get; init; }
    public bool? TodayIsClosedAllDay { get; init; }
}

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
}

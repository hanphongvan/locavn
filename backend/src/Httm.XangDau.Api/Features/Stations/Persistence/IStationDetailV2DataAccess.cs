namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary>Read API riêng cho <c>GET /api/stations/{id}/v2</c>.</summary>
public interface IStationDetailV2DataAccess
{
    /// <summary>
    /// Gọi <c>dbo.sp_Api_StationDetail_GetById_V2</c>. Trả về:
    /// <list type="bullet">
    ///   <item><c>Info</c> = null nếu không tồn tại station hoặc <c>CapDonViId</c> không khớp.</item>
    ///   <item><c>Prices</c> = list rỗng nếu station chưa khai báo giá nào trong <c>StationStoreServices</c>.</item>
    /// </list>
    /// </summary>
    Task<(StationDetailV2InfoSqlRow? Info, IReadOnlyList<StationDetailV2PriceSqlRow> Prices)> GetByIdAsync(
        int stationId,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);
}

using Httm.XangDau.Api.Features.StoreAdmin.StoreServices;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;
using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Features.Stations.Services;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Stations.Controllers;

/// <summary>Read APIs: petrol stations from <c>DM_DonVi</c> where <c>CapDonViId = 248</c>; optional <c>StationOperatingHours</c>.</summary>
[ApiController]
[Route("api/stations")]
[Tags("Stations")]
public sealed class StationsController(IStationReadService stationRead) : ControllerBase
{
    /// <summary>List stations (paged rows + total from <c>dbo.sp_Station_Search</c>). Use <c>province</c> or <c>provinceCode</c> for <c>DM_Tinh.Ma</c>. <c>status</c>: <c>all</c> | <c>open</c> | <c>closed</c> (Vietnam local time).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(PagedStationsResponse<StationListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PagedStationsResponse<StationListItemDto>>> List(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        [FromQuery] string? keyword = null,
        [FromQuery] string? province = null,
        [FromQuery] string? provinceCode = null,
        [FromQuery] string? districtCode = null,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default)
    {
        var provinceFilter = string.IsNullOrWhiteSpace(province) ? provinceCode : province;
        var (data, err) = await stationRead.ListAsync(skip, take, keyword, provinceFilter, districtCode, status, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>
    /// Map markers (paginated). <c>totalCount</c> when <c>skip == 0</c> only. Lightweight: coordinates, name, short address, prices, open hint.
    /// <c>keyword</c> (tùy chọn): LIKE trên tên, mã, địa chỉ, số giấy phép — cùng cột với <c>GET /api/stations</c>.
    /// </summary>
    [HttpGet("map")]
    [ProducesResponseType(typeof(PagedStationsResponse<StationMapItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PagedStationsResponse<StationMapItemDto>>> Map(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        [FromQuery] string? province = null,
        [FromQuery] string? provinceCode = null,
        [FromQuery] string? districtCode = null,
        [FromQuery] string? status = null,
        [FromQuery] string? keyword = null,
        CancellationToken cancellationToken = default)
    {
        var provinceFilter = string.IsNullOrWhiteSpace(province) ? provinceCode : province;
        var (data, err) = await stationRead.MapAsync(skip, take, provinceFilter, districtCode, status, keyword, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>
    /// Citizen viewport: trạm bán lẻ trong khung nhìn bản đồ (lat/lng bounding box) + optional <c>keyword</c>.
    /// Dùng khi mobile zoom đủ chi tiết (≥ 11). Cap mặc định <c>take=500</c>, max 1000 (validator).
    /// </summary>
    [HttpGet("map/bounds")]
    [ProducesResponseType(typeof(PagedStationsResponse<StationMapItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PagedStationsResponse<StationMapItemDto>>> MapBounds(
        [FromQuery] double minLat,
        [FromQuery] double maxLat,
        [FromQuery] double minLng,
        [FromQuery] double maxLng,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        [FromQuery] string? status = null,
        [FromQuery] string? keyword = null,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await stationRead.MapByBoundsCitizenAsync(
            skip, take, minLat, maxLat, minLng, maxLng, status, keyword, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>
    /// Province clusters cho zoom thấp (zoom &lt; 11): mỗi tỉnh = 1 marker tổng với count + centroid.
    /// Tránh render hàng nghìn marker khi user zoom xa. Optional <c>keyword</c> để cluster theo kết quả search.
    /// </summary>
    [HttpGet("map/clusters")]
    [ProducesResponseType(typeof(IReadOnlyList<StationMapProvinceClusterDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<StationMapProvinceClusterDto>>> MapClusters(
        [FromQuery] string? status = null,
        [FromQuery] string? keyword = null,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await stationRead.ProvinceClustersAsync(status, keyword, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>Canonical service codes + default labels for map filters (same source as store-admin catalog).</summary>
    [HttpGet("store-services-catalog")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminStoreServiceCatalogItemDto>), StatusCodes.Status200OK)]
    public ActionResult<IReadOnlyList<StoreAdminStoreServiceCatalogItemDto>> StoreServicesCatalog() =>
        Ok(StoreServiceCatalog.All);

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(StationDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationDetailDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var (data, err) = await stationRead.GetDetailAsync(id, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        if (data is null)
            return NotFound();
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}

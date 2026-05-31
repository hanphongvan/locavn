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
public sealed class StationsController(
    IStationReadService stationRead,
    IFuelProductReadService fuelProductRead) : ControllerBase
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
    /// V2 map markers. Tham số <c>fuelCode</c> (khớp <c>FuelProducts.Code</c> với
    /// <c>StationStoreServices.ServiceCode</c>) lọc trạm có đăng ký bán fuel đó (<c>IsActive</c>).
    /// Response thêm <c>priceForSelectedFuel</c>; <c>priceRon95</c>/<c>priceDiesel</c> lấy luôn từ
    /// <c>StationStoreServices.Price</c> trong cùng SP (V1 vẫn giữ cho app cũ).
    /// </summary>
    [HttpGet("map/v2")]
    [ProducesResponseType(typeof(PagedStationsResponse<StationMapItemV2Dto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PagedStationsResponse<StationMapItemV2Dto>>> MapV2(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        [FromQuery] string? province = null,
        [FromQuery] string? provinceCode = null,
        [FromQuery] string? districtCode = null,
        [FromQuery] string? status = null,
        [FromQuery] string? keyword = null,
        [FromQuery] string? fuelCode = null,
        CancellationToken cancellationToken = default)
    {
        var provinceFilter = string.IsNullOrWhiteSpace(province) ? provinceCode : province;
        var (data, err) = await stationRead.MapV2Async(skip, take, provinceFilter, districtCode, status, keyword, fuelCode, cancellationToken);
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

    /// <summary>
    /// Lá hoạt động của cây <c>FuelProducts</c> — public catalog cho chip "Loại nhiên liệu" trên bản đồ mobile.
    /// Code của lá khớp với <c>StationStoreServices.ServiceCode</c> khi cây xăng đăng ký bán fuel đó.
    /// </summary>
    [HttpGet("fuel-products/leaves")]
    [ProducesResponseType(typeof(IReadOnlyList<FuelProductLeafDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<FuelProductLeafDto>>> FuelProductLeaves(
        CancellationToken cancellationToken = default)
    {
        var data = await fuelProductRead.GetActiveLeavesAsync(cancellationToken);
        return Ok(data);
    }

    /// <summary>
    /// Đầu mối (<c>DM_DonVi.CapDonViId=235</c>) có trạm bán lẻ. Mobile dùng cho bottom sheet lọc.
    /// Sort theo số trạm giảm dần; brandKey/brandLogoUrl gắn từ <c>StationBranding</c> nếu cấu hình.
    /// </summary>
    [HttpGet("distributors")]
    [ProducesResponseType(typeof(IReadOnlyList<StationDistributorDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<StationDistributorDto>>> Distributors(
        CancellationToken cancellationToken = default)
    {
        var data = await stationRead.GetDistributorsAsync(cancellationToken);
        return Ok(data);
    }

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

    /// <summary>
    /// V2 — Detail cây xăng cho citizen. Dùng SP <c>sp_Api_StationDetail_GetById_V2</c>.
    /// Thay <c>latestReportingPrices</c> (10 dòng giá từ QT_TK_ThongKe) bằng <c>prices</c>
    /// — danh sách giá từ <c>StationStoreServices</c> với <c>ServiceCode</c> bắt đầu
    /// E5/E10/DIESEL/RON. V1 vẫn dùng cho app đã release.
    /// </summary>
    [HttpGet("{id:int}/v2")]
    [ProducesResponseType(typeof(StationDetailV2Dto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationDetailV2Dto>> GetByIdV2(int id, CancellationToken cancellationToken = default)
    {
        var (data, err) = await stationRead.GetDetailV2Async(id, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        if (data is null)
            return NotFound();
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}

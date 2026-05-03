using System.Text.Json.Serialization;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Serialization;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

/// <summary>First result set of <c>sp_StoreAdmin_StationPrices_GetBoardEditor</c>.</summary>
public sealed record StoreAdminStationPriceBoardEditorHeaderRow(
    int StationPricesId,
    int DonViId,
    DateTime ActiveDate,
    bool IsActive);

/// <summary>Payload for editing a full <c>StationPrices</c> board (same shape as batch create UI).</summary>
public sealed record StoreAdminStationPriceBoardEditorLineDto(
    int LineId,
    int ProductId,
    decimal Price,
    int? UnitId,
    string? Note);

public sealed record StoreAdminStationPriceBoardEditorResponseDto(
    int StationPricesId,
    int DonViId,
    DateTime ActiveDate,
    bool IsActive,
    IReadOnlyList<StoreAdminStationPriceBoardEditorLineDto> Lines);

public sealed class StoreAdminStationPriceBoardEditorSaveRequest
{
    [JsonConverter(typeof(VietnamWallDateTimeJsonConverter))]
    public DateTime EffectiveDate { get; set; }
    public bool IsCurrent { get; set; }
    public List<StoreAdminStationPriceBoardEditorSaveRow> Rows { get; set; } = [];
}

public sealed class StoreAdminStationPriceBoardEditorSaveRow
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public decimal Price { get; set; }
    public int? UnitId { get; set; }
    public string? Note { get; set; }
}

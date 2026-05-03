using System.Text.Json.Serialization;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Serialization;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

/// <summary>Update <c>StationPrices</c> header (ngày áp dụng, cờ hiệu lực).</summary>
public sealed class StoreAdminStationPriceBoardUpdateRequest
{
    [JsonConverter(typeof(VietnamWallDateTimeJsonConverter))]
    public DateTime ActiveDate { get; set; }
    public bool IsActive { get; set; }
}

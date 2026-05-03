using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Serialization;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

/// <summary>Body for POST/PUT — managed columns on <c>StationProductPrices</c> only.</summary>
public sealed class StoreAdminStorePriceUpsertRequest
{
    [Required]
    public int DonViId { get; set; }

    [Required]
    public int ProductId { get; set; }

    [Required]
    public decimal Price { get; set; }

    public int? UnitId { get; set; }

    [Required]
    [JsonConverter(typeof(VietnamWallDateTimeJsonConverter))]
    public DateTime EffectiveDate { get; set; }

    [Required]
    public bool IsCurrent { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

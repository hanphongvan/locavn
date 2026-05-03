using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Serialization;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

public sealed class StoreAdminStorePriceBatchRowRequest
{
    [Required]
    public int ProductId { get; set; }

    [Required]
    public decimal Price { get; set; }

    public int? UnitId { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

/// <summary>Batch create many <c>StationProductPrices</c> rows in one transaction (via stored procedure).</summary>
public sealed class StoreAdminStorePriceBatchCreateRequest
{
    [Required]
    public int DonViId { get; set; }

    [Required]
    [JsonConverter(typeof(VietnamWallDateTimeJsonConverter))]
    public DateTime EffectiveDate { get; set; }

    [Required]
    public bool IsCurrent { get; set; }

    [Required]
    [MinLength(1)]
    public List<StoreAdminStorePriceBatchRowRequest> Rows { get; set; } = [];
}

using System.Text.Json.Serialization;

namespace Httm.XangDau.Api.Features.Leader.Contracts;

/// <summary>
/// Leader dashboard fuel axis: **Xăng (gasoline)** and **Dầu (oil)** only.
/// There is <b>no</b> gas/LPG/Khí branch in this API surface — reporting <c>Nhom = 3</c> (Khí) is never mapped into these DTOs.
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum FuelType
{
    [JsonStringEnumMemberName("gasoline")]
    Gasoline,

    [JsonStringEnumMemberName("oil")]
    Oil,
}

/// <summary>National-level stock snapshot for one fuel (gasoline or oil only).</summary>
public sealed record NationalInventorySummary(
    FuelType FuelType,
    decimal? TotalQuantity,
    string? Unit,
    double? CoverageDays,
    decimal? ChangePercent,
    IReadOnlyList<decimal> SparklineData);

/// <summary>Import / export totals for one fuel (gasoline or oil only).</summary>
/// <remarks>Quantities may be null until dedicated reporting endpoints exist.</remarks>
public sealed record ImportExportSummary(
    FuelType FuelType,
    decimal? ImportQuantity,
    decimal? ExportQuantity,
    decimal? ImportChangePercent,
    decimal? ExportChangePercent);

/// <summary>Balance / position for one fuel (gasoline or oil only).</summary>
public sealed record BalanceSummary(
    FuelType FuelType,
    decimal? BalanceQuantity,
    decimal? ChangePercent,
    BalanceSummaryStatus Status);

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum BalanceSummaryStatus
{
    Ok,
    Warning,
    Critical,
    Unknown,
}

/// <summary>Map entity carrying **gasoline and oil** quantities/days only (no gas fields).</summary>
public sealed record MapInventoryMarker(
    string Id,
    string Name,
    MapInventoryUnitType UnitType,
    double Lat,
    double Lng,
    decimal? GasolineQuantity,
    double? GasolineDays,
    decimal? OilQuantity,
    double? OilDays,
    MapInventoryMarkerStatus Status);

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum MapInventoryUnitType
{
    [JsonStringEnumMemberName("station")]
    Station,

    [JsonStringEnumMemberName("distributor")]
    Distributor,
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum MapInventoryMarkerStatus
{
    Ok,
    Warning,
    Critical,
    Unknown,
}

/// <summary>Operational alert scoped to gasoline or oil only.</summary>
public sealed record LeaderAlert(
    string Id,
    string Title,
    string Description,
    FuelType FuelType,
    string Province,
    LeaderAlertSeverity Severity,
    LeaderAlertTargetType TargetType,
    DateTimeOffset CreatedAt);

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LeaderAlertSeverity
{
    Critical,
    Warning,
    Watch,
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LeaderAlertTargetType
{
    Province,
    Station,
    Distributor,
    System,
}

/// <summary>Single response bundle for leader clients (all sections exclude gas).</summary>
public sealed record LeaderDashboardSnapshotDto(
    IReadOnlyList<NationalInventorySummary> NationalInventory,
    IReadOnlyList<ImportExportSummary> ImportExport,
    IReadOnlyList<BalanceSummary> Balance,
    IReadOnlyList<MapInventoryMarker> MapMarkers,
    IReadOnlyList<LeaderAlert> Alerts);

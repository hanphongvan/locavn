namespace Httm.XangDau.Api.Features.ClientTelemetry;

/// <summary>Response cho <c>GET /api/admin/analytics/client-versions</c>.</summary>
public sealed record ClientVersionDistributionDto(
    DateTime FromDateUtc,
    DateTime ToDateUtc,
    long TotalUniqueClients,
    long TotalSamples,
    long LegacySamples,
    long VersionedSamples,
    IReadOnlyList<ClientVersionDistributionRow> ByVersion);

/// <summary>1 dòng / 1 (AppVersion, Platform). <c>UniqueClients</c> = INT (SQL COUNT()), <c>SampleCount</c> = BIGINT (COUNT_BIG).</summary>
public sealed record ClientVersionDistributionRow(
    string AppVersion,
    string Platform,
    int UniqueClients,
    long SampleCount);

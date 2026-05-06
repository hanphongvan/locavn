namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// 1 marker trong layer bản đồ AI.
/// </summary>
public sealed record AiMapMarkerDto(
    int Id,
    string Title,
    double Latitude,
    double Longitude,
    string? Category,
    string? Status);

/// <summary>
/// Mô tả layer bản đồ trong response (<c>data.map</c>) — chưa kết nối <c>core/map</c> ở Phase 1A.
/// </summary>
public sealed record AiMapDataDto(
    string LayerType,
    string Title,
    IReadOnlyList<AiMapMarkerDto> Markers);

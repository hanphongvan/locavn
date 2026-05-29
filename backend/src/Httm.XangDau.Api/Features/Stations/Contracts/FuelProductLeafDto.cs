namespace Httm.XangDau.Api.Features.Stations.Contracts;

/// <summary>
/// Một lá của cây <c>FuelProducts</c> (node không có con) — mobile dùng cho bộ lọc bản đồ.
/// <see cref="ParentCode"/> giúp client gom nhóm theo nhánh (XANG/DAU…) nếu cần.
/// </summary>
public sealed record FuelProductLeafDto(
    string Code,
    string Name,
    string? ParentCode,
    int SortOrder);

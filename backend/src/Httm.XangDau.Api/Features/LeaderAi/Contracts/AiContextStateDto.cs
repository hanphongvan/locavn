namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// Trạng thái context của hội thoại — phục vụ resolve câu rút gọn ở Phase 1B+.
/// Phase 1A (mock): được service trả về dưới dạng giá trị mặc định.
/// </summary>
public sealed record AiContextStateDto(
    string? LastIntent,
    string? LastTopic,
    int? LastRegionId,
    int? LastProvinceId,
    string? LastFuelType,
    string? LastProductCode,
    Guid? LastResultRef);

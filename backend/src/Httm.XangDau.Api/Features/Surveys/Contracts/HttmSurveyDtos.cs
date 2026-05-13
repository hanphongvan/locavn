namespace Httm.XangDau.Api.Features.Surveys.Contracts;

public sealed class HttmSurveyDto
{
    public Guid Id { get; init; }
    public string SurveyCode { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public short CurrentStep { get; init; }
    public string Step1Data { get; init; } = "{}";
    public string Step2Data { get; init; } = "{}";
    public string Step3Data { get; init; } = "{}";
    public string Step4Data { get; init; } = "{}";
    public string Step5Data { get; init; } = "{}";
    public string Step6Data { get; init; } = "{}";
    public string Step7Data { get; init; } = "{}";
    public string ConfirmerData { get; init; } = "{}";
    public string ProvinceCode { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public Guid? LinkedFacilityId { get; init; }
    public string CreatedBy { get; init; } = string.Empty;
    public DateTimeOffset? SubmittedAt { get; init; }
    public string? ReviewedBy { get; init; }
    public DateTimeOffset? ReviewedAt { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }
}

public sealed class HttmSurveyListItemDto
{
    public Guid Id { get; init; }
    public string SurveyCode { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string ProvinceCode { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public string CreatedBy { get; init; } = string.Empty;
    public DateTimeOffset CreatedAt { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }
}

public sealed class HttmSurveySearchPageDto
{
    public int TotalCount { get; init; }
    public IReadOnlyList<HttmSurveyListItemDto> Items { get; init; } = [];
}

public sealed class HttmSurveySearchQuery
{
    public string? Q { get; init; }
    public string? Status { get; init; }
    public string? ProvinceCode { get; init; }
    public string? HttmType { get; init; }
    public string? CreatedBy { get; init; }
    public DateTimeOffset? DateFrom { get; init; }
    public DateTimeOffset? DateTo { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}

public sealed class HttmSurveyCreateRequest
{
    public string ProvinceCode { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
}

public sealed class HttmSurveyPatchRequest
{
    public short? CurrentStep { get; init; }
    public string? Step1Data { get; init; }
    public string? Step2Data { get; init; }
    public string? Step3Data { get; init; }
    public string? Step4Data { get; init; }
    public string? Step5Data { get; init; }
    public string? Step6Data { get; init; }
    public string? Step7Data { get; init; }
    public string? ConfirmerData { get; init; }
}

public sealed class HttmSurveyApproveRequest
{
    public string? Notes { get; init; }
}

public sealed class HttmSurveyRejectRequest
{
    public string Reason { get; init; } = string.Empty;
}

public sealed class HttmSurveyHistoryDto
{
    public Guid Id { get; init; }
    public Guid SurveyId { get; init; }
    public string? FromStatus { get; init; }
    public string ToStatus { get; init; } = string.Empty;
    public string Action { get; init; } = string.Empty;
    public string? Notes { get; init; }
    public string PerformedBy { get; init; } = string.Empty;
    public DateTimeOffset PerformedAt { get; init; }
}

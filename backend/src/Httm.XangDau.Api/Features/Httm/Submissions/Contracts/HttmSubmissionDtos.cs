using Httm.XangDau.Api.Features.Httm.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Contracts;

/// <summary>Body POST <c>/api/public/httm/facility-submissions</c>.</summary>
public sealed class HttmSubmissionCreateRequest
{
    /// <summary>Trỏ đến facility hiện tại (cập nhật). <c>null</c> = đề xuất tạo mới.</summary>
    public Guid? FacilityId { get; init; }

    /// <summary>Toàn bộ dữ liệu facility do người dùng nhập — dùng đúng schema <see cref="HttmFacilityCreateRequest"/>.</summary>
    public HttmFacilityCreateRequest Payload { get; init; } = new();

    /// <summary>Ảnh đính kèm (đã upload qua <c>/api/public/httm/upload/image</c>). Khi approve sẽ insert vào <c>HttmFacilityImages</c>.</summary>
    public IReadOnlyList<HttmSubmissionImageDto> Images { get; init; } = [];

    /// <summary>Giấy tờ pháp lý đính kèm. Khi approve sẽ upsert vào <c>HttmFacilityLicenses</c>.</summary>
    public IReadOnlyList<HttmSubmissionLicenseDto> Licenses { get; init; } = [];

    public HttmSubmitterDto Submitter { get; init; } = new();
}

public sealed class HttmSubmissionImageDto
{
    /// <summary>URL trả từ upload endpoint (bắt đầu <c>/uploads/httm-submissions/</c>).</summary>
    public string Url { get; init; } = string.Empty;
    /// <summary><c>exterior|interior|infrastructure|other</c>.</summary>
    public string ImageType { get; init; } = "other";
    public string? Caption { get; init; }
    public DateOnly? TakenDate { get; init; }
    public short SortOrder { get; init; }
}

public sealed class HttmSubmissionLicenseDto
{
    /// <summary><c>business|fire_protection|food_safety|other</c>.</summary>
    public string LicenseType { get; init; } = "other";
    public string? LicenseNumber { get; init; }
    public DateOnly? IssuedDate { get; init; }
    public DateOnly? ExpiryDate { get; init; }
    public string? IssuedBy { get; init; }
    /// <summary>URL file đính kèm (PDF / ảnh scan, đã upload qua <c>/api/public/httm/upload/document</c>).</summary>
    public string? FileUrl { get; init; }
    public string? Notes { get; init; }
}

public sealed class HttmSubmitterDto
{
    public string Name { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? Notes { get; init; }
}

/// <summary>1 dòng trong list pending submissions (admin).</summary>
public sealed class HttmSubmissionListItemDto
{
    public Guid Id { get; init; }
    public Guid? FacilityId { get; init; }
    public string SubmissionType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? HttmType { get; init; }
    public string? ProvinceCode { get; init; }
    public string? WardCode { get; init; }
    public string SubmitterName { get; init; } = string.Empty;
    public string SubmitterPhone { get; init; } = string.Empty;
    public string? SubmitterEmail { get; init; }
    public DateTimeOffset SubmittedAt { get; init; }
    public string? ReviewedBy { get; init; }
    public DateTimeOffset? ReviewedAt { get; init; }
    public Guid? MergedFacilityId { get; init; }
}

public sealed class HttmSubmissionListPageDto
{
    public long TotalCount { get; init; }
    public IReadOnlyList<HttmSubmissionListItemDto> Items { get; init; } = [];
}

/// <summary>Detail page admin: proposed (parsed từ JSON) + current (nếu update).</summary>
public sealed class HttmSubmissionDetailDto
{
    public Guid Id { get; init; }
    public Guid? FacilityId { get; init; }
    public string SubmissionType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;

    /// <summary>Dữ liệu facility user submit (đã parse từ <c>PayloadJson</c>).</summary>
    public HttmFacilityCreateRequest Proposed { get; init; } = new();

    /// <summary>Ảnh đính kèm user submit (admin xem preview).</summary>
    public IReadOnlyList<HttmSubmissionImageDto> ProposedImages { get; init; } = [];

    /// <summary>Giấy tờ pháp lý user submit.</summary>
    public IReadOnlyList<HttmSubmissionLicenseDto> ProposedLicenses { get; init; } = [];

    /// <summary>Snapshot facility hiện tại (chỉ với type=update). <c>null</c> nếu type=create_new hoặc facility đã xoá.</summary>
    public HttmFacilityDto? Current { get; init; }

    public HttmSubmitterDto Submitter { get; init; } = new();
    public DateTimeOffset SubmittedAt { get; init; }
    public string? SubmitterIp { get; init; }

    public string? ReviewedBy { get; init; }
    public DateTimeOffset? ReviewedAt { get; init; }
    public string? ReviewNotes { get; init; }
    public Guid? MergedFacilityId { get; init; }
}

/// <summary>
/// Wrapper serialize vào <c>HttmFacilitySubmissions.PayloadJson</c>: chứa thông tin facility +
/// ảnh + giấy tờ pháp lý do public user submit kèm.
/// </summary>
public sealed class HttmSubmissionPayloadWrapper
{
    public HttmFacilityCreateRequest Facility { get; init; } = new();
    public IReadOnlyList<HttmSubmissionImageDto> Images { get; init; } = [];
    public IReadOnlyList<HttmSubmissionLicenseDto> Licenses { get; init; } = [];
}

public sealed class HttmSubmissionApproveRequest
{
    public string? Notes { get; init; }
}

public sealed class HttmSubmissionRejectRequest
{
    public string Reason { get; init; } = string.Empty;
}

public sealed class HttmSubmissionReviewResultDto
{
    public Guid SubmissionId { get; init; }
    public string Status { get; init; } = string.Empty;
    public Guid? MergedFacilityId { get; init; }
}

/// <summary>Light facility row trả cho public dialog chọn — không có sensitive fields.</summary>
public sealed class HttmPublicFacilityRowDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string HttmType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string ProvinceCode { get; init; } = string.Empty;
    public string? DistrictCode { get; init; }
    public string? WardCode { get; init; }
    public string? AddressDetail { get; init; }
}

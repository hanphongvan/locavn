using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.BadReports.Contracts;

/// <summary>POST <c>/api/bad-reports</c> body. Optional <see cref="StationId"/> must reference a petrol station when set.</summary>
public sealed record CreateBadReportRequestDto(
    int? StationId,
    string Content,
    IReadOnlyList<string>? ImageUrls);

/// <summary>Public acknowledgement — no report body or status.</summary>
public sealed record CreateBadReportResponseDto(int Id, DateTime CreatedAt);

/// <summary>POST <c>/api/bad-reports/upload-image</c> — absolute URL for <see cref="CreateBadReportRequestDto.ImageUrls"/>.</summary>
public sealed record BadReportImageUploadResponseDto(string Url);

public sealed record BadReportImageDto(int Id, string ImageUrl);

public sealed record AdminBadReportListItemDto(
    int Id,
    int? StationId,
    string Content,
    DateTime CreatedAt,
    StationBadReportStatus Status,
    int ImageCount);

public sealed record AdminBadReportPageDto(
    IReadOnlyList<AdminBadReportListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);

public sealed record AdminBadReportDetailDto(
    int Id,
    int? StationId,
    string Content,
    DateTime CreatedAt,
    StationBadReportStatus Status,
    IReadOnlyList<BadReportImageDto> Images);

/// <summary>GET <c>/api/my-bad-reports</c> — báo vi phạm do người dùng đã đăng nhập gửi (<see cref="StationBadReport.ReporterUserId"/>).</summary>
public sealed record MyBadReportListItemDto(
    int Id,
    int? StationId,
    string? StationName,
    string Content,
    DateTime CreatedAt,
    StationBadReportStatus Status,
    int ImageCount);

public sealed record MyBadReportPageDto(
    IReadOnlyList<MyBadReportListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);

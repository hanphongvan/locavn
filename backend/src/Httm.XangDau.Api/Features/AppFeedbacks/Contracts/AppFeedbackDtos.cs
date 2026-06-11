using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Contracts;

/// <summary>POST <c>/api/app-feedback</c> body. Gửi được ẩn danh; <c>Category</c> theo <see cref="AppFeedbackCategory"/> (0=Bug,1=Suggestion,2=Other).</summary>
public sealed record CreateAppFeedbackRequestDto(
    AppFeedbackCategory Category,
    string Content,
    string? ContactEmail,
    string? ContactPhone,
    string? AppVersion,
    string? Platform,
    IReadOnlyList<string>? ImageUrls);

/// <summary>Xác nhận đã nhận góp ý — không trả lại nội dung.</summary>
public sealed record CreateAppFeedbackResponseDto(int Id, DateTime CreatedAt);

/// <summary>POST <c>/api/app-feedback/upload-image</c> — URL tuyệt đối cho <see cref="CreateAppFeedbackRequestDto.ImageUrls"/>.</summary>
public sealed record AppFeedbackImageUploadResponseDto(string Url);

public sealed record AppFeedbackImageDto(int Id, string ImageUrl);

public sealed record AdminAppFeedbackListItemDto(
    int Id,
    AppFeedbackCategory Category,
    string Content,
    string? ContactEmail,
    string? ContactPhone,
    string? AppVersion,
    string? Platform,
    bool FromAuthenticatedUser,
    DateTime CreatedAt,
    AppFeedbackStatus Status,
    int ImageCount);

public sealed record AdminAppFeedbackPageDto(
    IReadOnlyList<AdminAppFeedbackListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);

public sealed record AdminAppFeedbackDetailDto(
    int Id,
    AppFeedbackCategory Category,
    string Content,
    string? ContactEmail,
    string? ContactPhone,
    string? AppVersion,
    string? Platform,
    string? UserId,
    DateTime CreatedAt,
    AppFeedbackStatus Status,
    IReadOnlyList<AppFeedbackImageDto> Images);

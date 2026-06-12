namespace Httm.XangDau.Api.Features.AppVersionPolicy;

/// <summary>Cờ cấu hình runtime cho app mobile (<c>GET /api/app/config</c>). Đọc từ appsettings, bật/tắt không cần build app.</summary>
public sealed record AppConfigDto(bool FeedbackEnabled);

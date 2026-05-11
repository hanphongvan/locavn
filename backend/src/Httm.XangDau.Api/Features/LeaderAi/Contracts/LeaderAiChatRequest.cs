using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// Context client gửi kèm câu hỏi — giúp Phase 1B+ resolve câu rút gọn theo màn hình hiện tại.
/// Ở Phase 1A chỉ lưu vào <c>AiConversationContexts</c> (chưa dùng để LLM resolve).
/// </summary>
public sealed record LeaderAiChatContext(
    string? Screen,
    int? ProvinceId,
    int? RegionId,
    string? FuelType,
    string? SelectedLayer,
    int? SelectedEntityId,
    string? SelectedEntityType);

/// <summary>
/// Body của <c>POST /api/leader-ai/chat</c>.
/// </summary>
public sealed record LeaderAiChatRequest(
    // Validation phải gắn parameter của primary constructor (không dùng [property: ...]) —
    // ASP.NET Core model validation sẽ ném InvalidOperationException nếu chỉ có metadata trên property.
    [Required(AllowEmptyStrings = false), MinLength(1), MaxLength(2000)]
    string Message,
    Guid? ConversationId,
    LeaderAiChatContext? Context);

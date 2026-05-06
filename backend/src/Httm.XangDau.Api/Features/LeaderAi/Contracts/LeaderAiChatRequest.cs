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
    // Cú pháp [property: ...] để DataAnnotation áp lên property auto-gen của record positional —
    // [Required] trên parameter không tự propagate xuống property nên ModelValidation sẽ bỏ qua.
    [property: Required(AllowEmptyStrings = false), MinLength(1), MaxLength(2000)]
    string Message,
    Guid? ConversationId,
    LeaderAiChatContext? Context);

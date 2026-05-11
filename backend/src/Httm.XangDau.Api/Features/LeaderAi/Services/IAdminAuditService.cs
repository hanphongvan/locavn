namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 5G — best-effort write <c>AiAdminAuditLogs</c>. Section 13A.1 yêu cầu
/// mọi admin action (approve / reject / promote / disable_entity / ...) đều ghi
/// audit để Phase 5H/6 dashboard truy vết + compliance.
///
/// "Best-effort": ghi audit fail KHÔNG fail business operation chính. Chỉ log
/// warning. Phase 5G admin endpoint vẫn trả 200 nếu mutation thành công nhưng
/// audit insert lỗi.
/// </summary>
public interface IAdminAuditService
{
    /// <summary>
    /// Ghi 1 audit row. <paramref name="action"/> theo enum spec
    /// (<c>approve_intent</c> / <c>reject_intent</c> / <c>promote_intent</c> / ...).
    /// <paramref name="beforeJson"/> + <paramref name="afterJson"/> là snapshot
    /// JSON state trước/sau action (nullable — vd promote không có before).
    /// </summary>
    Task LogAsync(
        int adminUserId,
        string action,
        string? tableName = null,
        string? recordId = null,
        string? beforeJson = null,
        string? afterJson = null,
        string? notes = null,
        CancellationToken cancellationToken = default);
}

/// <summary>Action enum tham khảo — string constant để tránh enum serialize lung tung.</summary>
public static class AdminAuditActions
{
    public const string ApproveIntent = "approve_intent";
    public const string RejectIntent = "reject_intent";
    public const string PromoteIntent = "promote_intent";
    public const string AutoFlagCandidate = "auto_flag_candidate";
    // Phase 5H/6 sẽ thêm: create_entity, update_entity, disable_entity, ...
}

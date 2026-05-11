namespace Httm.XangDau.Api.Features.Fuel.Voice.Services;

public interface IFuelTransactionVoiceParser
{
    /// <summary>
    /// Parse câu tiếng Việt từ Whisper → fields cho form đổ nhiên liệu.
    /// Phase 1 (P0): bắt số tiền + số km. Ngày mặc định = today nếu không nói.
    /// Phase 2-3 (P1-P3): ngày, lít, số chữ, trạm... — chưa cover trong P0.
    /// </summary>
    ParsedFuelTransactionResult Parse(string rawText);
}

/// <summary>Kết quả parse — caller map sang DTO để trả về client.</summary>
public sealed record ParsedFuelTransactionResult(
    long? AmountVnd,
    long? OdometerKm,
    DateTime TransactionDate,
    IReadOnlyList<string> MissingRequiredFields);

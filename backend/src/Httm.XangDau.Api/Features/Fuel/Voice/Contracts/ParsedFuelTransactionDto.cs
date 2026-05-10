namespace Httm.XangDau.Api.Features.Fuel.Voice.Contracts;

/// <summary>
/// Response của <c>POST /api/fuel/voice/parse-fuel-tx</c>. Field nullable nếu không
/// nghe được — mobile nhận DTO này, prefill form, user xem rồi bấm Lưu.
/// </summary>
public sealed class ParsedFuelTransactionDto
{
    /// <summary>Text Whisper nghe được — luôn có để show user khi parse fail.</summary>
    public required string RawText { get; init; }

    /// <summary>Số tiền (VNĐ) — bắt buộc cho form. Null = parse fail → mobile show fail dialog.</summary>
    public long? AmountVnd { get; init; }

    /// <summary>Số công tơ km — optional.</summary>
    public long? OdometerKm { get; init; }

    /// <summary>Ngày giao dịch — default = today nếu không nói tới ngày.</summary>
    public DateTime TransactionDate { get; init; }

    /// <summary>Liệt kê các field bắt buộc bị missing — mobile dùng để hiển dialog phù hợp.</summary>
    public IReadOnlyList<string> MissingRequiredFields { get; init; } = [];

    /// <summary>Mã lỗi nội bộ (whisper_unreachable, audio_too_large, ...) — null nghĩa là OK.</summary>
    public string? Error { get; init; }
}

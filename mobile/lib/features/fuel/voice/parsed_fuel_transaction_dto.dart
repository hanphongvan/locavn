/// Mirror BE `ParsedFuelTransactionDto`. `amountVnd == null` → parse fail field bắt buộc,
/// mobile show fail dialog. `error != null` cho biết lý do (whisper_*, audio_*, transcribe_empty).
class ParsedFuelTransactionDto {
  const ParsedFuelTransactionDto({
    required this.rawText,
    required this.transactionDate,
    this.amountVnd,
    this.odometerKm,
    this.missingRequiredFields = const [],
    this.error,
  });

  final String rawText;
  final int? amountVnd;
  final int? odometerKm;
  final DateTime transactionDate;
  final List<String> missingRequiredFields;
  final String? error;

  bool get hasAmount => amountVnd != null && amountVnd! > 0;

  factory ParsedFuelTransactionDto.fromJson(Map<String, dynamic> json) {
    return ParsedFuelTransactionDto(
      rawText: (json['rawText'] as String?) ?? '',
      amountVnd: (json['amountVnd'] as num?)?.toInt(),
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
      transactionDate: DateTime.tryParse(json['transactionDate'] as String? ?? '') ?? DateTime.now(),
      missingRequiredFields: ((json['missingRequiredFields'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      error: json['error'] as String?,
    );
  }
}

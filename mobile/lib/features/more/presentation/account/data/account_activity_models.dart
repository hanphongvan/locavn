import '../../../../../core/network/json_utils.dart';

/// `GET /api/account/activity-summary`
class AccountActivitySummary {
  const AccountActivitySummary({
    required this.reviewsCount,
    required this.reportsCount,
    required this.fuelTransactionsCount,
  });

  final int reviewsCount;
  final int reportsCount;
  final int fuelTransactionsCount;

  factory AccountActivitySummary.fromJson(Map<String, dynamic> json) {
    return AccountActivitySummary(
      reviewsCount: JsonUtils.readInt(json['reviewsCount']) ?? 0,
      reportsCount: JsonUtils.readInt(json['reportsCount']) ?? 0,
      fuelTransactionsCount: JsonUtils.readInt(json['fuelTransactionsCount']) ?? 0,
    );
  }
}

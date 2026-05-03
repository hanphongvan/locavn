import '../../../core/network/json_utils.dart';

List<T> _listMap<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
  final list = JsonUtils.readList(raw);
  if (list == null) return const [];
  final out = <T>[];
  for (final e in list) {
    final m = JsonUtils.readMap(e);
    if (m != null) out.add(f(m));
  }
  return out;
}

class StabilizationFundMonthlyPointDto {
  const StabilizationFundMonthlyPointDto({
    required this.year,
    required this.month,
    required this.totalBalance,
  });

  final int year;
  final int month;
  final double totalBalance;

  factory StabilizationFundMonthlyPointDto.fromJson(Map<String, dynamic> json) {
    return StabilizationFundMonthlyPointDto(
      year: JsonUtils.readInt(json['year']) ?? 0,
      month: JsonUtils.readInt(json['month']) ?? 0,
      totalBalance: JsonUtils.readDouble(json['totalBalance']) ?? 0,
    );
  }
}

class StabilizationFundSummaryDto {
  const StabilizationFundSummaryDto({
    required this.totalBalance,
    required this.changeFromPreviousMonth,
    required this.reportedDistributorCount,
    required this.notReportedDistributorCount,
    required this.abnormalDistributorCount,
    required this.monthlyTrend,
    required this.reportMonth,
    required this.reportYear,
    required this.reportCutoffDayOfMonth,
  });

  final double totalBalance;
  final double changeFromPreviousMonth;
  final int reportedDistributorCount;
  final int notReportedDistributorCount;
  final int abnormalDistributorCount;
  final List<StabilizationFundMonthlyPointDto> monthlyTrend;
  /// Kỳ BC08 đang hiển thị (đồng bộ với tham số gọi SP).
  final int reportMonth;
  final int reportYear;
  /// Mốc ngày trong tháng (VN): nếu ngày hiện tại lớn hơn mốc thì kỳ “mới nhất” là tháng trước; ngược lại là tháng trước nữa.
  final int reportCutoffDayOfMonth;

  factory StabilizationFundSummaryDto.fromJson(Map<String, dynamic> json) {
    return StabilizationFundSummaryDto(
      totalBalance: JsonUtils.readDouble(json['totalBalance']) ?? 0,
      changeFromPreviousMonth: JsonUtils.readDouble(json['changeFromPreviousMonth']) ?? 0,
      reportedDistributorCount: JsonUtils.readInt(json['reportedDistributorCount']) ?? 0,
      notReportedDistributorCount: JsonUtils.readInt(json['notReportedDistributorCount']) ?? 0,
      abnormalDistributorCount: JsonUtils.readInt(json['abnormalDistributorCount']) ?? 0,
      monthlyTrend: _listMap(json['monthlyTrend'], StabilizationFundMonthlyPointDto.fromJson),
      reportMonth: JsonUtils.readInt(json['reportMonth']) ?? 0,
      reportYear: JsonUtils.readInt(json['reportYear']) ?? 0,
      reportCutoffDayOfMonth: JsonUtils.readInt(json['reportCutoffDayOfMonth']) ?? 20,
    );
  }
}

class StabilizationFundDistributorRow {
  const StabilizationFundDistributorRow({
    required this.distributorId,
    required this.distributorName,
    this.address,
    this.balance,
    this.increaseAmount,
    this.decreaseAmount,
    this.endingBalance,
    required this.reportMonth,
    required this.reportYear,
    required this.reportStatus,
    this.changeFromPreviousMonth,
    this.note,
    this.updatedAt,
  });

  final int distributorId;
  final String distributorName;
  final String? address;
  final double? balance;
  final double? increaseAmount;
  final double? decreaseAmount;
  final double? endingBalance;
  final int reportMonth;
  final int reportYear;
  final String reportStatus;
  final double? changeFromPreviousMonth;
  final String? note;
  final DateTime? updatedAt;

  factory StabilizationFundDistributorRow.fromJson(Map<String, dynamic> json) {
    return StabilizationFundDistributorRow(
      distributorId: JsonUtils.readInt(json['distributorId']) ?? 0,
      distributorName: JsonUtils.readString(json['distributorName']) ?? '',
      address: JsonUtils.readString(json['address']),
      balance: JsonUtils.readDouble(json['balance']),
      increaseAmount: JsonUtils.readDouble(json['increaseAmount']),
      decreaseAmount: JsonUtils.readDouble(json['decreaseAmount']),
      endingBalance: JsonUtils.readDouble(json['endingBalance']),
      reportMonth: JsonUtils.readInt(json['reportMonth']) ?? 0,
      reportYear: JsonUtils.readInt(json['reportYear']) ?? 0,
      reportStatus: JsonUtils.readString(json['reportStatus']) ?? '',
      changeFromPreviousMonth: JsonUtils.readDouble(json['changeFromPreviousMonth']),
      note: JsonUtils.readString(json['note']),
      updatedAt: JsonUtils.readDateTime(json['updatedAt']),
    );
  }
}

class StabilizationFundDistributorsDto {
  const StabilizationFundDistributorsDto({required this.items});

  final List<StabilizationFundDistributorRow> items;

  factory StabilizationFundDistributorsDto.fromJson(Map<String, dynamic> json) {
    return StabilizationFundDistributorsDto(
      items: _listMap(json['items'], StabilizationFundDistributorRow.fromJson),
    );
  }
}

class StabilizationFundHistoryRow {
  const StabilizationFundHistoryRow({
    required this.month,
    required this.year,
    required this.beginningBalance,
    required this.increaseAmount,
    required this.decreaseAmount,
    required this.endingBalance,
  });

  final int month;
  final int year;
  final double beginningBalance;
  final double increaseAmount;
  final double decreaseAmount;
  final double endingBalance;

  factory StabilizationFundHistoryRow.fromJson(Map<String, dynamic> json) {
    return StabilizationFundHistoryRow(
      month: JsonUtils.readInt(json['month']) ?? 0,
      year: JsonUtils.readInt(json['year']) ?? 0,
      beginningBalance: JsonUtils.readDouble(json['beginningBalance']) ?? 0,
      increaseAmount: JsonUtils.readDouble(json['increaseAmount']) ?? 0,
      decreaseAmount: JsonUtils.readDouble(json['decreaseAmount']) ?? 0,
      endingBalance: JsonUtils.readDouble(json['endingBalance']) ?? 0,
    );
  }
}

class StabilizationFundHistoryDto {
  const StabilizationFundHistoryDto({required this.items});

  final List<StabilizationFundHistoryRow> items;

  factory StabilizationFundHistoryDto.fromJson(Map<String, dynamic> json) {
    return StabilizationFundHistoryDto(
      items: _listMap(json['items'], StabilizationFundHistoryRow.fromJson),
    );
  }
}

import 'package:flutter/foundation.dart';

@immutable
class FuelSummaryUi {
  const FuelSummaryUi({
    required this.totalCostDong,
    required this.totalLiters,
    required this.costPerKmDong,
    required this.costChangePercent,
    required this.literChangePercent,
    required this.costPerKmChangePercent,
  });

  final int totalCostDong;
  final double totalLiters;
  final int costPerKmDong;
  final double costChangePercent;
  final double literChangePercent;
  final double costPerKmChangePercent;
}

@immutable
class FuelInsightUi {
  const FuelInsightUi({
    required this.mainComment,
    required this.secondaryInsight,
  });

  final String mainComment;
  final String secondaryInsight;
}

@immutable
class FuelTransactionUi {
  const FuelTransactionUi({
    required this.id,
    required this.amountDong,
    required this.liters,
    this.odometerKm,
    this.note,
    required this.transactionDate,
  });

  final String id;
  final int amountDong;
  final double liters;
  final double? odometerKm;
  final String? note;
  final DateTime transactionDate;
}

/// Dữ liệu ban đầu khi sửa giao dịch — truyền qua [GoRouterState.extra].
class FuelTransactionEditPrefill {
  const FuelTransactionEditPrefill({
    required this.transactionId,
    required this.amountDong,
    required this.transactionDate,
    this.odometerKm,
    this.note,
  });

  final int transactionId;
  final int amountDong;
  final double? odometerKm;
  final String? note;
  final DateTime transactionDate;
}

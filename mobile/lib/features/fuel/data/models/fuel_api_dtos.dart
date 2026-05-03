import 'package:flutter/foundation.dart';

import '../../../../core/network/json_utils.dart';

@immutable
class CurrentVehicleApiDto {
  const CurrentVehicleApiDto({
    required this.vehicleId,
    this.vehicleName,
    required this.licensePlate,
    this.fuelType,
    this.imageUrl,
  });

  final int vehicleId;
  final String? vehicleName;
  final String licensePlate;
  final String? fuelType;
  final String? imageUrl;

  factory CurrentVehicleApiDto.fromJson(Map<String, dynamic> json) {
    return CurrentVehicleApiDto(
      vehicleId: JsonUtils.readInt(json['vehicleId']) ?? 0,
      vehicleName: json['vehicleName'] as String?,
      licensePlate: (json['licensePlate'] as String?)?.trim() ?? '',
      fuelType: json['fuelType'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

@immutable
class FuelSummaryApiDto {
  const FuelSummaryApiDto({
    required this.totalCost,
    required this.totalLiters,
    required this.costPerKm,
    required this.costChangePercent,
    required this.literChangePercent,
    required this.costPerKmChangePercent,
  });

  final double totalCost;
  final double totalLiters;
  final double costPerKm;
  final double costChangePercent;
  final double literChangePercent;
  final double costPerKmChangePercent;

  factory FuelSummaryApiDto.fromJson(Map<String, dynamic> json) {
    return FuelSummaryApiDto(
      totalCost: JsonUtils.readDouble(json['totalCost']) ?? 0,
      totalLiters: JsonUtils.readDouble(json['totalLiters']) ?? 0,
      costPerKm: JsonUtils.readDouble(json['costPerKm']) ?? 0,
      costChangePercent: JsonUtils.readDouble(json['costChangePercent']) ?? 0,
      literChangePercent: JsonUtils.readDouble(json['literChangePercent']) ?? 0,
      costPerKmChangePercent: JsonUtils.readDouble(json['costPerKmChangePercent']) ?? 0,
    );
  }
}

@immutable
class FuelInsightApiDto {
  const FuelInsightApiDto({required this.mainText, required this.savingText});

  final String mainText;
  final String savingText;

  factory FuelInsightApiDto.fromJson(Map<String, dynamic> json) {
    return FuelInsightApiDto(
      mainText: (json['mainText'] as String?)?.trim() ?? '',
      savingText: (json['savingText'] as String?)?.trim() ?? '',
    );
  }
}

@immutable
class FuelTransactionApiDto {
  const FuelTransactionApiDto({
    required this.id,
    required this.transactionDate,
    this.stationId,
    required this.stationName,
    this.stationLogo,
    this.distanceText,
    required this.amount,
    required this.liters,
    required this.pricePerLiter,
    this.odometer,
    this.note,
  });

  final int id;
  final DateTime transactionDate;
  final int? stationId;
  final String stationName;
  final String? stationLogo;
  final String? distanceText;
  final double amount;
  final double liters;
  final double pricePerLiter;
  final double? odometer;
  final String? note;

  factory FuelTransactionApiDto.fromJson(Map<String, dynamic> json) {
    return FuelTransactionApiDto(
      id: JsonUtils.readInt(json['id']) ?? 0,
      transactionDate: JsonUtils.readDateTime(json['transactionDate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      stationId: JsonUtils.readInt(json['stationId']),
      stationName: (json['stationName'] as String?)?.trim() ?? '',
      stationLogo: json['stationLogo'] as String?,
      distanceText: json['distanceText'] as String?,
      amount: JsonUtils.readDouble(json['amount']) ?? 0,
      liters: JsonUtils.readDouble(json['liters']) ?? 0,
      pricePerLiter: JsonUtils.readDouble(json['pricePerLiter']) ?? 0,
      odometer: JsonUtils.readDouble(json['odometer']),
      note: JsonUtils.readString(json['note'])?.trim(),
    );
  }
}

@immutable
class FuelTransactionsPageApiDto {
  const FuelTransactionsPageApiDto({required this.items, required this.totalCount});

  final List<FuelTransactionApiDto> items;
  final int totalCount;

  factory FuelTransactionsPageApiDto.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['items']);
    final list = <FuelTransactionApiDto>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          list.add(FuelTransactionApiDto.fromJson(m));
        }
      }
    }
    return FuelTransactionsPageApiDto(
      items: list,
      totalCount: JsonUtils.readInt(json['totalCount']) ?? 0,
    );
  }
}

@immutable
class CreateFuelTransactionResultDto {
  const CreateFuelTransactionResultDto({required this.success, required this.message, this.id});

  final bool success;
  final String message;
  final int? id;

  factory CreateFuelTransactionResultDto.fromJson(Map<String, dynamic> json) {
    return CreateFuelTransactionResultDto(
      success: json['success'] == true,
      message: (json['message'] as String?)?.trim() ?? '',
      id: JsonUtils.readInt(json['id']),
    );
  }
}

import '../../../../core/network/json_utils.dart';

/// Backend `VehicleDto` (camelCase JSON).
class VehicleDto {
  const VehicleDto({
    required this.id,
    required this.licensePlate,
    this.vehicleName,
    this.fuelType,
    this.fuelLevel,
    this.totalKm,
    this.year,
    required this.isDefault,
    this.imageUrl,
  });

  final int id;
  final String licensePlate;
  final String? vehicleName;
  final String? fuelType;
  final int? fuelLevel;
  final int? totalKm;
  final int? year;
  final bool isDefault;
  final String? imageUrl;

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      licensePlate: JsonUtils.readStringRequired(json['licensePlate'], field: 'licensePlate'),
      vehicleName: JsonUtils.readString(json['vehicleName']),
      fuelType: JsonUtils.readString(json['fuelType']),
      fuelLevel: JsonUtils.readInt(json['fuelLevel']),
      totalKm: JsonUtils.readInt(json['totalKm']),
      year: JsonUtils.readInt(json['year']),
      isDefault: JsonUtils.readBool(json['isDefault']) ?? false,
      imageUrl: JsonUtils.readString(json['imageUrl']),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return <String, dynamic>{
      'licensePlate': licensePlate,
      'vehicleName': vehicleName,
      'fuelType': fuelType,
      'fuelLevel': fuelLevel,
      'totalKm': totalKm,
      'year': year,
      'isDefault': isDefault,
      'imageUrl': imageUrl,
    };
  }
}

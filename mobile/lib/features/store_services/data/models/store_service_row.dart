import '../../../../core/network/json_utils.dart';

const Object _sentinel = Object();

/// Backend: `StoreAdminStoreServiceListItemDto`.
class StoreServiceRow {
  const StoreServiceRow({
    required this.id,
    required this.donViId,
    required this.serviceCode,
    required this.displayName,
    required this.iconKey,
    required this.isActive,
    required this.price,
    required this.sortOrder,
  });

  final int id;
  final int donViId;
  final String serviceCode;
  final String displayName;
  final String? iconKey;
  final bool isActive;
  final double? price;
  final int sortOrder;

  StoreServiceRow copyWith({
    int? id,
    int? donViId,
    String? serviceCode,
    String? displayName,
    String? iconKey,
    bool? isActive,
    Object? price = _sentinel,
    int? sortOrder,
  }) {
    return StoreServiceRow(
      id: id ?? this.id,
      donViId: donViId ?? this.donViId,
      serviceCode: serviceCode ?? this.serviceCode,
      displayName: displayName ?? this.displayName,
      iconKey: iconKey ?? this.iconKey,
      isActive: isActive ?? this.isActive,
      price: price == _sentinel ? this.price : price as double?,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory StoreServiceRow.fromJson(Map<String, dynamic> json) {
    return StoreServiceRow(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      donViId: JsonUtils.readIntRequired(json['donViId'], field: 'donViId'),
      serviceCode: JsonUtils.readStringRequired(json['serviceCode'], field: 'serviceCode'),
      displayName: JsonUtils.readStringRequired(json['displayName'], field: 'displayName'),
      iconKey: JsonUtils.readString(json['iconKey']),
      isActive: JsonUtils.readBool(json['isActive']) ??
          (throw const FormatException('Missing or invalid isActive')),
      price: JsonUtils.readDouble(json['price']),
      sortOrder: JsonUtils.readInt(json['sortOrder']) ?? 0,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'displayName': displayName,
        'isActive': isActive,
        'price': price,
        'sortOrder': sortOrder,
      };
}

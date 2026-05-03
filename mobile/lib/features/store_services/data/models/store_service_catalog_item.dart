import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminStoreServiceCatalogItemDto`.
class StoreServiceCatalogItem {
  const StoreServiceCatalogItem({
    required this.serviceCode,
    required this.defaultDisplayName,
    required this.iconKey,
    required this.supportsOptionalPrice,
  });

  final String serviceCode;
  final String defaultDisplayName;
  final String? iconKey;
  final bool supportsOptionalPrice;

  factory StoreServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return StoreServiceCatalogItem(
      serviceCode: JsonUtils.readStringRequired(json['serviceCode'], field: 'serviceCode'),
      defaultDisplayName:
          JsonUtils.readStringRequired(json['defaultDisplayName'], field: 'defaultDisplayName'),
      iconKey: JsonUtils.readString(json['iconKey']),
      supportsOptionalPrice: JsonUtils.readBool(json['supportsOptionalPrice']) ?? false,
    );
  }
}

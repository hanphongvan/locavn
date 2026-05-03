class StoreServiceCreateRequest {
  const StoreServiceCreateRequest({
    required this.donViId,
    required this.serviceCode,
    this.displayName,
    this.isActive = true,
    this.price,
    this.sortOrder = 0,
  });

  final int donViId;
  final String serviceCode;
  final String? displayName;
  final bool isActive;
  final double? price;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'donViId': donViId,
        'serviceCode': serviceCode,
        if (displayName != null && displayName!.trim().isNotEmpty) 'displayName': displayName!.trim(),
        'isActive': isActive,
        'price': price,
        'sortOrder': sortOrder,
      };
}

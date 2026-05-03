import 'package:flutter/material.dart';

/// Maps backend `iconKey` (Material symbol-ish names) to [IconData].
IconData storeServiceIconData(String? iconKey) {
  switch (iconKey) {
    case 'wc':
      return Icons.wc_outlined;
    case 'local_car_wash':
      return Icons.local_car_wash_outlined;
    case 'storefront':
      return Icons.storefront_outlined;
    case 'oil_barrel':
      return Icons.oil_barrel_outlined;
    case 'tire_repair':
      return Icons.tire_repair_outlined;
    case 'atm':
      return Icons.atm_outlined;
    case 'local_parking':
      return Icons.local_parking_outlined;
    case 'wifi':
      return Icons.wifi_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'ev_station':
      return Icons.ev_station_outlined;
    case 'chair':
      return Icons.chair_outlined;
    default:
      return Icons.room_service_outlined;
  }
}

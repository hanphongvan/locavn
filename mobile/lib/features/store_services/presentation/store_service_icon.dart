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

/// Icon ưu tiên theo [serviceCode] khi là sản phẩm nhiên liệu (`StationStoreServices.ServiceCode`
/// trùng `FuelProducts.Code`): `RON*` / `E5*` / `E10*` → bơm xăng; `DIESEL*` → thùng dầu.
/// Các code khác fallback về [storeServiceIconData] với [iconKey] do store-admin / catalog cấu hình.
IconData storeServiceIconForCode(String? serviceCode, String? iconKey) {
  if (serviceCode != null) {
    final u = serviceCode.trim().toUpperCase();
    if (u.startsWith('DIESEL')) {
      return Icons.oil_barrel_outlined;
    }
    if (u.startsWith('E5') || u.startsWith('E10') || u.startsWith('RON')) {
      return Icons.local_gas_station_outlined;
    }
  }
  return storeServiceIconData(iconKey);
}

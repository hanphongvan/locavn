import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/features/inventory_stock_map/data/models/inventory_map_response.dart';

void main() {
  test('InventoryMapResponse parses StoreAdminInventoryMapResponseDto shape', () {
    final m = jsonDecode(r'''
{
  "stations": [
    {
      "stationId": 1,
      "stationCode": "S001",
      "stationName": "Test",
      "address": "Addr",
      "latitude": 10.5,
      "longitude": 106.2,
      "currentQuantity": 100.5,
      "stockStatus": "normal"
    }
  ]
}
''') as Map<String, dynamic>;

    final r = InventoryMapResponse.fromJson(m);
    expect(r.stations, hasLength(1));
    final s = r.stations.single;
    expect(s.stationId, 1);
    expect(s.stationCode, 'S001');
    expect(s.stationName, 'Test');
    expect(s.address, 'Addr');
    expect(s.latitude, 10.5);
    expect(s.longitude, 106.2);
    expect(s.currentQuantity, 100.5);
    expect(s.stockStatus, 'normal');
  });

  test('InventoryMapResponse accepts PascalCase Stations envelope', () {
    final m = jsonDecode(r'''
{
  "Stations": [
    {
      "stationId": 2,
      "stationCode": "S2",
      "stationName": "Pascal",
      "address": null,
      "latitude": 11,
      "longitude": 107,
      "currentQuantity": 0,
      "stockStatus": "low"
    }
  ]
}
''') as Map<String, dynamic>;

    final r = InventoryMapResponse.fromJson(m);
    expect(r.stations, hasLength(1));
    expect(r.stations.single.stationName, 'Pascal');
  });
}

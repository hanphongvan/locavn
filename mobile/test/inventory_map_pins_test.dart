import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/features/inventory_stock_map/data/models/inventory_map_station.dart';
import 'package:httm_xangdau/features/inventory_stock_map/domain/stock_map_stock_status.dart';
import 'package:httm_xangdau/features/inventory_stock_map/map/inventory_stock_map_pins_from_api.dart';

void main() {
  test('parseInventoryMapStockStatus accepts server casing', () {
    expect(parseInventoryMapStockStatus('OUT'), StockMapStockStatus.out);
    expect(parseInventoryMapStockStatus(' Low '), StockMapStockStatus.low);
    expect(parseInventoryMapStockStatus('normal'), StockMapStockStatus.normal);
    expect(parseInventoryMapStockStatus('unknown'), isNull);
  });

  test('pinsFromInventoryMapStations skips invalid coords or status', () {
    final pins = pinsFromInventoryMapStations([
      const InventoryMapStation(
        stationId: 1,
        stationCode: 'A',
        stationName: 'Ok',
        address: null,
        latitude: 10,
        longitude: 106,
        currentQuantity: 1,
        stockStatus: 'normal',
      ),
      const InventoryMapStation(
        stationId: 2,
        stationCode: 'B',
        stationName: 'No lat',
        address: null,
        latitude: null,
        longitude: 106,
        currentQuantity: 0,
        stockStatus: 'normal',
      ),
      const InventoryMapStation(
        stationId: 3,
        stationCode: 'C',
        stationName: 'Bad status',
        address: null,
        latitude: 11,
        longitude: 107,
        currentQuantity: 0,
        stockStatus: 'weird',
      ),
    ]);
    expect(pins, hasLength(1));
    expect(pins.single.stationId, 1);
    expect(pins.single.status, StockMapStockStatus.normal);
  });
}

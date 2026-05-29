# Map providers (HTTM & Admin)

Tài liệu này mô tả **nền bản đồ** dùng cho Admin Angular (HTTM, bản đồ tồn kho) và tuân thủ hiển thị **Hoàng Sa / Trường Sa** trên client.

## OSM / Carto (mặc định Phase 1)

- **Tile URL (Carto Positron, OSM data):**  
  `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png`
- **Attribution (rút gọn):** `© OpenStreetMap contributors © CARTO`
- **Max zoom:** 19 (theo cấu hình Leaflet trong app).

Nền này được dùng trong:

- `admin/src/app/features/inventory-map/inventory-map-page.component.ts`
- `admin/src/app/features/httm/pages/httm-map-page.component.ts` + `HttmMapService` (tuỳ chọn `osm`).

## Nhãn Hoàng Sa / Trường Sa (cartographic reference)

- **Implementation:** `admin/src/app/features/inventory-map/inventory-map-geo-labels.ts` — hàm `mountSeaIslandGeoLabels(map)`.
- **HTTM:** bản đồ HTTM gọi lại cùng helper để đồng bộ vị trí nhãn.
- **Lưu ý pháp lý:** nhãn là tham chiếu bản đồ nhỏ; không thay thế tuyên bố chủ quyền ngoài kênh ngoại giao.

## Goong.io (tuỳ chọn)

- **Trạng thái:** Phase 1 **chưa** gắn tile URL Goong thật trong Angular; toggle `goong` trong UI vẫn dùng nền Carto cho đến khi có `httm.map.goong_api_key` từ `AppSystemSettings` (seed migration HTTM) và logic đọc cấu hình từ API.
- **Khi tích hợp:** tile URL và điều khoản sử dụng phải lấy từ tài liệu chính thức Goong; **bắt buộc** kiểm tra hiển thị Hoàng Sa / Trường Sa trên nền Goong trước khi bật production.

## Cấu hình backend (tham chiếu)

Khóa trong `dbo.AppSystemSettings` (xem migration HTTM checklist §1.1.5):

| Key | Ý nghĩa |
|-----|---------|
| `httm.map.provider` | `osm` hoặc tương lai `goong` |
| `httm.map.goong_api_key` | API key (không commit giá trị thật) |
| `httm.map.default_center_lng` / `lat` / `default_zoom` | Khung nhìn mặc định |

## Liên quan

- Domain schema: [`docs/modules/httm/data-model-sqlserver.md`](../modules/httm/data-model-sqlserver.md)
- Checklist: [`docs/modules/httm/checklist.md`](../modules/httm/checklist.md) — §1.3.6 compliance

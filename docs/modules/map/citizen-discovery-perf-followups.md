# Bản đồ Citizen — Cải thiện hiệu năng "Gần nhất" / "Rẻ nhất" (follow-up)

## Bối cảnh

Vai trò Citizen (Loai=5) phản ánh trang **Bản đồ** load chậm khi bấm chip
**Gần nhất** / **Rẻ nhất**. Audit ngày 2026-05-06 phát hiện **5 nguyên nhân**;
2 cái nặng nhất (UX + GPS cache) đã fix tại commit cùng ngày. **3 cái còn lại**
ở dưới — apply tiếp khi vẫn thấy chậm.

Mỗi mục có severity, file/line, đoạn code minh hoạ, và mức tác động ước tính.

---

## 🔴 #1 — Backend `/api/stations/nearest` quét bảng toàn bộ

**File:** [`backend/src/Httm.XangDau.Api/Features/Stations/Services/StationSpotlightReadService.cs`](../../../backend/src/Httm.XangDau.Api/Features/Stations/Services/StationSpotlightReadService.cs)
&nbsp;&nbsp;`GetNearestAsync`, dòng 30–35.

```csharp
var row = await db.DmDonVis.AsNoTracking().WherePetrolRetailWithValidMapCoordinates()
    .OrderBy(d =>
        (d.ViDo!.Value - latDec) * (d.ViDo.Value - latDec)
        + (d.KinhDo!.Value - lngDec) * (d.KinhDo.Value - lngDec))
    .Select(...)
    .FirstOrDefaultAsync(cancellationToken);
```

`OrderBy` bằng biểu thức số học trên `ViDo`/`KinhDo` ⇒ DB **không dùng được index**,
phải tính khoảng cách cho **mọi cây xăng petrol retail** (vài nghìn dòng) rồi sort full.
p95 hiện tại ước cỡ vài trăm ms — vài giây tuỳ tải DB.

### Fix đề xuất

Tiền lọc bằng bounding box ~25 km rồi mới `OrderBy` (chỉ vài chục dòng vào sort):

```csharp
// ~0.225° ≈ 25 km cho VN. Nếu rỗng, mở rộng dần (50 → 100 km) rồi mới fallback full scan.
const decimal latPad = 0.225m;
var lngPad = (decimal)(0.225 / Math.Max(0.2, Math.Cos(lat * Math.PI / 180.0)));

var query = db.DmDonVis.AsNoTracking()
    .WherePetrolRetailWithValidMapCoordinates()
    .Where(d => d.ViDo  >= latDec - latPad && d.ViDo  <= latDec + latPad)
    .Where(d => d.KinhDo >= lngDec - lngPad && d.KinhDo <= lngDec + lngPad);

var row = await query
    .OrderBy(d => (d.ViDo!.Value - latDec) * (d.ViDo.Value - latDec)
                + (d.KinhDo!.Value - lngDec) * (d.KinhDo.Value - lngDec))
    .Select(d => new { d.Id, d.Ten, Addr = d.DiaChiChiTiet ?? d.DiaChi, d.ViDo, d.KinhDo })
    .FirstOrDefaultAsync(cancellationToken);
```

Tốt nhất kèm composite index `(CapDonViId, ViDo, KinhDo)` trên `DmDonVi`
để 2 `Where` mới dùng được index range scan.

### Edge case cần xử lý

- Vùng biên giới / hải đảo có thể không có trạm trong 25 km → fallback mở rộng
  (50 → 100 km → full scan).
- Ở Hoàng Sa / Trường Sa: hầu như sẽ rỗng cho tới full scan; chấp nhận được
  vì tần suất truy cập từ vùng này thấp.

### Tác động ước tính

p95 endpoint giảm từ "vài trăm ms – vài giây" xuống **< 50 ms** với index phù hợp.

---

## 🟡 #3 — Sheet "Rẻ nhất" gọi GPS lại mỗi lần đổi RON95 ↔ Diesel

**File:** [`mobile/lib/features/map/presentation/map_cheapest_station.dart`](../../../mobile/lib/features/map/presentation/map_cheapest_station.dart)
&nbsp;&nbsp;`_CheapestSpotlightSheetState`, `onSelectionChanged` ~ dòng 356–360.

```dart
onSelectionChanged: (Set<CheapestFuelQuery> next) {
  if (next.isEmpty) return;
  setState(() => _fuel = next.first);
  _load();   // re-run requestMapUserLocation toàn bộ
},
```

`_load()` re-run cả flow GPS + tính cheapest. Vị trí user trong cùng một sheet
**không thay đổi** ⇒ lần GPS thứ 2 trở đi là dư thừa (dù sau fix #2 đã có
last-known cache 2 phút, vẫn còn 1 round-trip vào platform channel của Geolocator).

### Fix đề xuất

Cache `AppLatLng _cachedUserPos` trong state, lần đầu lấy GPS, các lần toggle sau
dùng lại:

```dart
class _CheapestSpotlightSheetState extends ConsumerState<_CheapestSpotlightSheet> {
  AppLatLng? _cachedUserPos;
  // ...

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final items = ref.read(stationMapMarkersProvider).asData?.value.items ?? const [];
    if (items.isEmpty) { /* … như cũ … */ return; }

    AppLatLng? pos = _cachedUserPos;
    if (pos == null) {
      final loc = await requestMapUserLocation(
        acceptLastKnownMaxAge: const Duration(minutes: 2),
      );
      if (!mounted) return;
      switch (loc) {
        case MapUserLocationOk(:final position):
          pos = position;
          _cachedUserPos = position;
        case MapUserLocationDenied():
        case MapUserLocationDeniedForever():
        case MapUserLocationServiceDisabled():
        case MapUserLocationGnssTimeout():
          // setState error tương ứng rồi return — như code hiện tại
      }
    }

    final item = pickCheapestStationInRadiusFromLoadedMarkers(
      items: items,
      userLat: pos!.latitude,
      userLng: pos.longitude,
      fuel: _fuel,
    );
    // … phần còn lại không đổi
  }
}
```

### Tác động ước tính

Toggle RON95 ↔ Diesel trong sheet **gần như tức thời** (chỉ là lọc tuyến tính
trong list marker đã tải, vài chục micro-giây).

---

## 🟡 #5 — Backend `GetRatingAggregateAsync` chạy 3 query tuần tự

**File:** [`backend/src/Httm.XangDau.Api/Features/Stations/Services/StationSpotlightReadService.cs`](../../../backend/src/Httm.XangDau.Api/Features/Stations/Services/StationSpotlightReadService.cs)
&nbsp;&nbsp;`GetRatingAggregateAsync`, dòng 155–167.

```csharp
var any = await db.StationReviews.AsNoTracking().AnyAsync(...);   // round-trip 1
if (!any) return (null, null);
var avg = await db.StationReviews.AsNoTracking().Where(...).AverageAsync(...); // round-trip 2
var cnt = await db.StationReviews.AsNoTracking().CountAsync(...);              // round-trip 3
```

Ba round-trip này **luôn** chạy cho mỗi lần "Gần nhất" (nearest path không có
rating sẵn nên rơi vào nhánh aggregate). Cộng dồn với #1 ⇒ p95 endpoint
nhân lên đáng kể.

### Fix đề xuất

Một query duy nhất, group + aggregate:

```csharp
private async Task<(double? Average, int? Count)> GetRatingAggregateAsync(
    int stationId, CancellationToken cancellationToken)
{
    var agg = await db.StationReviews.AsNoTracking()
        .Where(r => r.StationId == stationId)
        .GroupBy(r => 1)
        .Select(g => new {
            Avg = g.Average(r => (double)r.Rating),
            Cnt = g.Count(),
        })
        .FirstOrDefaultAsync(cancellationToken);
    if (agg is null) return (null, null);
    return (Math.Round(agg.Avg, 2, MidpointRounding.AwayFromZero), agg.Cnt);
}
```

### Tác động ước tính

Endpoint nearest tiết kiệm 2 round-trip DB (~10–30 ms tuỳ độ trễ mạng nội bộ).
Ảnh hưởng nhỏ hơn #1 nhưng dễ làm và an toàn.

---

## Thứ tự nên làm tiếp

Xếp theo **lợi ích / công sức**:

1. **#3** (cache GPS trong sheet Rẻ nhất) — chỉ động mobile, 1 file, không cần redeploy backend. ~15 phút.
2. **#5** (gộp 3 query rating) — 1 method backend, dễ test, ít rủi ro. ~10 phút + smoke test.
3. **#1** (bbox prefilter + index) — sửa root cause backend, **đo lại** với prod data trước/sau bằng SQL profiler. ~30 phút + index migration.

Sau khi áp #1, có thể bỏ luôn fallback "local nearest" trong
[`map_nearest_station.dart`](../../../mobile/lib/features/map/presentation/map_nearest_station.dart)
nếu quyết định API là single source of truth — nhưng giữ lại cũng không sao,
chỉ là dead path khi mạng OK.

---

## Đã fix (commit `2ff210b` ngày 2026-05-06)

- 🔴 **#2** — `requestMapUserLocation(acceptLastKnownMaxAge: 2 phút)` cho cả
  Gần nhất và Rẻ nhất, tránh re-acquire GNSS 20s mỗi lần bấm.
- 🟡 **#4** — Spinner trên 2 chip pill ("Gần nhất" / "Rẻ nhất") + chống tap
  lặp; thêm callback `onResolveDone` cho `presentNearestPetrolStation` để
  tắt spinner đúng lúc sheet/snackbar xuất hiện.

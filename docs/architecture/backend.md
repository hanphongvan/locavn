# Backend Architecture Guidelines

## 1. Data Access Principle

All data access in the system MUST follow the Stored Procedure First architecture.

### Rules:

- All APIs MUST call SQL Server Stored Procedures.
- Direct table queries from application code are NOT allowed.
- Do NOT use:
  - Entity Framework direct DbSet queries
  - LINQ to Entities for business data access
  - Inline SQL queries in code

- ONLY allowed:
  - ADO.NET or Dapper
  - Execute stored procedures

## 2. Stored Procedure Responsibilities

Stored procedures are responsible for:
- Data retrieval (SELECT)
- Data insertion (INSERT)
- Data update (UPDATE)
- Business logic related to data processing
- Batch operations (if applicable)

## 3. API Layer Responsibilities

API layer MUST:
- Call stored procedures only
- Map request DTO → stored procedure parameters
- Map result sets → response DTO
- NOT contain business data logic

## 4. Naming Convention

Stored procedures should follow consistent naming:

- SP_<Module>_<Action>
Examples:
- SP_StorePrices_SaveBatch
- SP_StorePrices_GetLatest
- SP_FuelProducts_GetAll

## 5. Transaction Handling

- If multiple data operations are involved, transactions should be handled inside stored procedures.
- API layer should not manage complex transactions unless absolutely necessary.

## 6. Schema Source of Truth

- All tables and columns must be defined in `docs/architecture/database.md`
- Application code must NOT assume or invent schema

## 7. HTTM module (`Features/Httm`)

Phase 1 thêm domain **Hạ tầng thương mại** vào API `Httm.XangDau.Api`:

| Thư mục / file | Vai trò |
|-----------------|---------|
| `Features/Httm/Controllers/` | `HttmFacilityController` (`/api/httm`), `HttmCatalogController` (`/api/catalogs`) |
| `Features/Httm/Services/` | `HttmFacilityService` — orchestration, phân quyền nhạy cảm, phạm vi tỉnh |
| `Features/Httm/Persistence/` | Dapper + stored procedure (`IHttmFacilityRepository`, …) |
| `Features/Httm/Validators/` | FluentValidation |
| `Features/Httm/HttmDependencyInjection.cs` | `AddHttmFeature()` |

Đăng ký: `FeatureDependencyInjection.AddFeatureModules` gọi `AddHttmFeature()`.

Tài liệu chi tiết: [`docs/modules/httm/data-model-sqlserver.md`](../modules/httm/data-model-sqlserver.md), [`docs/modules/httm/checklist.md`](../modules/httm/checklist.md).

## 8. Surveys — phiếu khảo sát (`Features/Surveys`)

Phase 2: workflow draft → submitted → reviewing → approved/rejected; tạo hồ sơ từ phiếu đã duyệt qua `POST /api/httm/from-survey/{surveyId}`.

| Thư mục / file | Vai trò |
|-----------------|---------|
| `Features/Surveys/Controllers/SurveyController.cs` | `/api/surveys` |
| `Features/Surveys/Services/HttmSurveyService.cs` | Phân quyền, map phiếu → `HttmFacilityCreateRequest` |
| `Features/Surveys/Persistence/` | Dapper + `sp_Httm_Survey_*`, `sp_Httm_Facility_LinkSourceSurvey` |
| `Features/Surveys/SurveysDependencyInjection.cs` | `AddSurveysFeature()` |

Đăng ký: `AddFeatureModules` gọi `AddSurveysFeature()` sau `AddHttmFeature()`. SQL migrations: `backend/database/migrations/2026051315*.sql`.

## 9. Tương thích ngược với mobile đã release

**Quy tắc bắt buộc**: trước khi sửa bất kỳ endpoint/contract nào ở backend, phải tính đến **bản app mobile cũ đang chạy trên thiết bị người dùng**. App đã phát hành không thể cập nhật ngay lập tức — luôn có một khoảng thời gian (vài tuần đến vài tháng) app cũ vẫn gọi API theo cách cũ.

### Trước khi sửa endpoint, hỏi 3 câu

1. **Cách gọi cũ có còn chạy được không?** Param cũ vẫn được nhận, response shape vẫn đúng, status code không đổi?
2. **Nếu thêm field bắt buộc / xóa field / đổi kiểu / đổi semantic** → đây là **breaking change**. App cũ sẽ lỗi parse, lỗi validate, hoặc hiểu nhầm dữ liệu.
3. **Nếu không thể giữ tương thích** → KHÔNG sửa endpoint cũ. Tạo endpoint mới (`/api/.../v2`, hoặc tên khác). App mới gọi endpoint mới, app cũ tiếp tục dùng endpoint cũ cho đến khi adoption đạt ngưỡng.

### Các thay đổi backward-compatible (an toàn)

- ✅ Thêm param tùy chọn (`[FromQuery] string? newParam = null`) — default null = hành vi cũ.
- ✅ Thêm field tùy chọn vào DTO response (app cũ bỏ qua field lạ).
- ✅ Mở rộng enum chỉ ở chỗ output (app cũ vẫn parse được).
- ✅ Sửa hành vi nội bộ (SP, batch, cache) miễn là contract giữ nguyên.

### Các thay đổi KHÔNG backward-compatible (cần endpoint mới)

- ❌ Đổi tên field trong response DTO.
- ❌ Đổi kiểu dữ liệu (int → string, single → array).
- ❌ Xóa field hoặc xóa enum value.
- ❌ Thêm validate strict hơn (param trước cho phép null, giờ bắt buộc).
- ❌ Đổi semantic của param (`status=open` trước nghĩa A, giờ nghĩa B).
- ❌ Đổi URL path hoặc HTTP method.
- ❌ Đổi status code cho cùng tình huống (200 → 204, 200 → 400).

### Ví dụ minh họa (đã áp dụng trong [fix `f55de9d`](#))

**Bối cảnh**: keyword search ở tab Bản đồ trên mobile không ra kết quả vì client cap 750 markers, mà DB có ~12k trạm bán lẻ. Phương án sạch nhất (Phase 2) là thêm param `keyword` cho `/api/stations/map`.

**Vấn đề**: app cũ đang chạy sẽ không truyền `keyword` → vẫn miss kết quả.

**Cách xử lý**:
- Phase 1 (backend-only, không phá app cũ): chỉ thay đổi *hành vi nội bộ* — bật gzip, override `take=50000` khi `skip=0`, batch `ids.Contains`, tắt OPENJSON translation. Tất cả giữ nguyên contract → app cũ tự nhận lợi ích nhờ short-circuit pagination ở client.
- Phase 2 (sau khi app mới release): thêm param `keyword` (tùy chọn, default null) cho `/api/stations/map` — vẫn backward-compatible vì param mới là optional. Khi đó gỡ hack `take=50000`.

### Kiểm tra trước khi commit

- Diff response shape của endpoint sửa với version trước (Swagger / response example).
- Nếu sửa SP, đảm bảo signature `@Param` cũ vẫn nhận được (param mới phải có DEFAULT).
- Nếu sửa controller, đảm bảo route + verb + status code giữ nguyên cho cách gọi cũ.
- Khi không chắc, **mặc định an toàn**: tạo endpoint mới thay vì sửa endpoint cũ.
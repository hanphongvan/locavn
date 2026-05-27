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
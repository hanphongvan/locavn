using FluentValidation;
using Httm.XangDau.Api.Features.Httm.Import.Services;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Features.Httm.Submissions.Persistence;
using Httm.XangDau.Api.Features.Httm.Submissions.Services;
using Httm.XangDau.Api.Features.Httm.Validators;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.Httm;

/// <summary>Đăng ký dịch vụ domain HTTM (Hạ tầng thương mại). Repositories, validators, policies: §1.2.4+.</summary>
public static class HttmDependencyInjection
{
    public static IServiceCollection AddHttmFeature(this IServiceCollection services)
    {
        services.AddScoped<IHttmFacilityRepository, HttmFacilityRepository>();
        services.AddScoped<IHttmCatalogRepository, HttmCatalogRepository>();
        services.AddScoped<IHttmAuditLogRepository, HttmAuditLogRepository>();
        services.AddScoped<IHttmImageStorage, LocalHttmImageStorage>();
        services.AddScoped<IHttmFacilityService, HttmFacilityService>();
        services.AddValidatorsFromAssemblyContaining<HttmFacilityCreateValidator>();

        // Import Excel — 3-step wizard (template / validate / confirm). Cache session 10 phút.
        services.AddMemoryCache();
        services.AddScoped<HttmExcelTemplateBuilder>();
        services.AddScoped<HttmExcelParser>();
        services.AddScoped<IHttmImportService, HttmImportService>();

        // Public Submissions (đề xuất cập nhật/tạo mới) — bảng tạm + admin review + upload ảnh/giấy tờ.
        services.AddScoped<IHttmSubmissionRepository, HttmSubmissionRepository>();
        services.AddScoped<IHttmSubmissionService, HttmSubmissionService>();
        services.AddScoped<IPublicSubmissionFileStorage, PublicSubmissionFileStorage>();
        return services;
    }
}

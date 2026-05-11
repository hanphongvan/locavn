using Httm.XangDau.Api.Shared.DataAccess;
using Httm.XangDau.Api.Shared.Middleware;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Reporting;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.DependencyInjection;

public static class InfrastructureDependencyInjection
{
    public const string DefaultConnectionName = "DefaultConnection";

    /// <summary>
    /// Phase 5F (refactored) — connection string riêng cho user <c>ai_readonly</c>.
    /// Dùng bởi <see cref="LeaderAi.Persistence.AdminAiDataAccess.ExecuteDynamicQuerySafelyAsync"/>
    /// để execute dynamic SQL từ AI Gateway. Section 7.8 docs/loca-ai-phase5.md.
    ///
    /// Đặt vào <c>ConnectionStrings:AiReadonly</c> trong appsettings.json. Empty
    /// → endpoint <c>POST /internal/ai/exec-dynamic-query</c> trả 503 (Phase 5F
    /// degrade graceful, AI Gateway fall back Phase 5E plan preview).
    /// </summary>
    public const string AiReadonlyConnectionName = "AiReadonly";

    /// <summary>
    /// Registers EF Core SQL Server using <c>ConnectionStrings:DefaultConnection</c>.
    /// Override with environment variable <c>ConnectionStrings__DefaultConnection</c> (or user secrets in Development).
    /// </summary>
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddExceptionHandler<GlobalExceptionHandler>();
        services.AddProblemDetails();

        var connectionString = configuration.GetConnectionString(DefaultConnectionName);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                $"Connection string '{DefaultConnectionName}' is missing. Set ConnectionStrings:{DefaultConnectionName} in appsettings, " +
                "environment variable ConnectionStrings__DefaultConnection, or user secrets.");
        }

        services.AddDbContext<DmpPortalDbContext>(options =>
            options.UseSqlServer(connectionString));

        services.AddHttpContextAccessor();
        services.AddScoped<IAdminPortalRequestContext, AdminPortalRequestContext>();

        // Phase 5H — IMemoryCache cho /internal/ai/latest-period (5 phút TTL,
        // giảm round-trip xuống view view_AiHeadOffice* khi LLM gọi mỗi câu).
        services.AddMemoryCache();

        services.AddDataAccess();

        services.AddScoped<IThongKePeriodResolver, ThongKePeriodResolver>();

        services.Configure<AdminApiKeyOptions>(configuration.GetSection(AdminApiKeyOptions.SectionName));
        services.AddPortalOAuthAndJwtBearer(configuration);
        services.AddAuthorization();

        return services;
    }
}

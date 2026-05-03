using System.Text.Json;
using System.Threading.RateLimiting;
using Httm.XangDau.Api.Features;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Swagger;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Configuration (first wins for same key): environment variables → appsettings.{Environment}.json → appsettings.json
// SQL Server: set ConnectionStrings__DefaultConnection to override ConnectionStrings:DefaultConnection (double underscore = nested section).

builder.Logging.AddSimpleConsole(options => options.TimestampFormat = "HH:mm:ss ");

builder.Services.AddControllers().AddJsonOptions(o =>
{
    o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    o.JsonSerializerOptions.DictionaryKeyPolicy = JsonNamingPolicy.CamelCase;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "HTTM Xăng dầu — DMPPortal API (demo)",
        Version = "v1",
        Description =
            "Phase 1 scaffold. Existing database DMPPortal — see docs/architecture/database.md (no invented columns). " +
            $"Admin routes: **Bearer** JWT from `POST /api/oauth/token` (or `POST /api/oauth/store-admin/token`), or header **{AdminApiKeyDefaults.ApiKeyHeaderName}** (configure Admin:ApiKey)."
    });
    options.AddSecurityDefinition("AdminApiKey", new OpenApiSecurityScheme
    {
        Description = $"Admin API key in header **{AdminApiKeyDefaults.ApiKeyHeaderName}**.",
        Name = AdminApiKeyDefaults.ApiKeyHeaderName,
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
    });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT from `POST /api/oauth/token` or `POST /api/oauth/store-admin/token` (Authorization: Bearer {token}).",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
    });
    options.OperationFilter<AdminApiKeyOperationFilter>();
});

builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddFeatureModules(builder.Configuration);

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (ctx, token) =>
    {
        ctx.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        await ctx.HttpContext.Response
            .WriteAsJsonAsync(new { message = "Quá nhiều yêu cầu. Vui lòng thử lại sau." }, token)
            .ConfigureAwait(false);
    };

    static string PartitionKey(HttpContext http) =>
        http.Connection.RemoteIpAddress?.ToString() ?? "unknown";

    options.AddPolicy(
        "forgot-password",
        httpContext => RateLimitPartition.GetFixedWindowLimiter(
            PartitionKey(httpContext),
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(15),
                QueueLimit = 0,
            }));

    options.AddPolicy(
        "reset-password",
        httpContext => RateLimitPartition.GetFixedWindowLimiter(
            PartitionKey(httpContext),
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(15),
                QueueLimit = 0,
            }));
});

var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
var hasCorsOrigins = corsOrigins.Length > 0;
if (hasCorsOrigins)
{
    builder.Services.AddCors(o =>
        o.AddDefaultPolicy(p => p.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod()));
}

var app = builder.Build();

app.ApplyDmpPortalMigrations();
app.SeedFuelProductCatalogIfNeeded();

app.UseExceptionHandler();
app.UseStatusCodePages();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options => options.SwaggerEndpoint("/swagger/v1/swagger.json", "v1"));
}

// CORS phải bọc ngoài UseHttpsRedirection: redirect HTTP→HTTPS không gọi next() nên nếu đặt CORS sau thì response thiếu Access-Control-Allow-Origin (trình duyệt báo lỗi CORS).
if (hasCorsOrigins)
{
    app.UseCors();
}

if (builder.Configuration.GetValue("UseHttpsRedirection", defaultValue: true))
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.MapControllers();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }))
    .WithTags("Health")
    .WithName("HealthCheck");

app.Run();

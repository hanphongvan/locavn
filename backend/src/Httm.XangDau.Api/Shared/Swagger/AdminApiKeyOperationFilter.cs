using System.Reflection;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace Httm.XangDau.Api.Shared.Swagger;

public sealed class AdminApiKeyOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var authorize = GetAuthorize(context.MethodInfo);
        if (authorize is null)
            return;

        operation.Security ??= new List<OpenApiSecurityRequirement>();
        foreach (var scheme in ParseSchemes(authorize))
        {
            var id = scheme == JwtBearerDefaults.AuthenticationScheme ? "Bearer" : "AdminApiKey";
            operation.Security.Add(new OpenApiSecurityRequirement
            {
                [new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = id },
                }] = Array.Empty<string>(),
            });
        }
    }

    private static AuthorizeAttribute? GetAuthorize(MethodInfo method)
    {
        if (method.GetCustomAttribute<AuthorizeAttribute>(inherit: true) is { } m)
            return m;
        return method.DeclaringType?.GetCustomAttribute<AuthorizeAttribute>(inherit: true);
    }

    private static IEnumerable<string> ParseSchemes(AuthorizeAttribute authorize)
    {
        if (string.IsNullOrWhiteSpace(authorize.AuthenticationSchemes))
        {
            yield return AdminApiKeyDefaults.AuthenticationScheme;
            yield break;
        }

        foreach (var part in authorize.AuthenticationSchemes.Split(
                     ',',
                     StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
            yield return part;
    }
}

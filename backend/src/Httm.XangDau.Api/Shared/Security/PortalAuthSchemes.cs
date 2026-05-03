using Microsoft.AspNetCore.Authentication.JwtBearer;

namespace Httm.XangDau.Api.Shared.Security;

/// <summary>Composite scheme names for endpoints that accept machine credentials or portal JWTs.</summary>
public static class PortalAuthSchemes
{
    /// <summary>
    /// <see cref="AdminApiKeyDefaults.AuthenticationScheme"/> or <see cref="JwtBearerDefaults.AuthenticationScheme"/> (Bearer).
    /// </summary>
    public const string AdminApiKeyOrBearer =
        AdminApiKeyDefaults.AuthenticationScheme + "," + JwtBearerDefaults.AuthenticationScheme;
}

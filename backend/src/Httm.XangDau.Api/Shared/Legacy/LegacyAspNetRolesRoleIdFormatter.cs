namespace Httm.XangDau.Api.Shared.Legacy;

/// <summary>
/// Normalizes values for <see cref="Httm.XangDau.Api.Shared.Persistence.Entities.AspNetRole.Id"/> /
/// <see cref="Httm.XangDau.Api.Shared.Persistence.Entities.AspNetUserRole.RoleId"/>
/// (<c>nvarchar(128)</c>, <c>docs/architecture/database.md</c>).
/// </summary>
/// <remarks>
/// Production <c>AspNetRoles.Id</c> values are 36-character hyphenated GUIDs with <b>uppercase</b> hex (typical SQL
/// <c>newid()</c> string form). <see cref="Guid.ToString(string)"/> with <c>"D"</c> is lowercase in .NET, so we uppercase
/// after formatting. Non-GUID strings are returned trimmed unchanged.
/// </remarks>
public static class LegacyAspNetRolesRoleIdFormatter
{
    /// <summary>
    /// Trims; if the value parses as a <see cref="Guid"/>, returns <c>ToString("D")</c> in <b>uppercase</b>; otherwise the
    /// trimmed string.
    /// </summary>
    public static string FormatForAspNetTables(string? roleIdFromRequestOrDb)
    {
        var s = roleIdFromRequestOrDb?.Trim() ?? string.Empty;
        if (s.Length == 0)
        {
            return string.Empty;
        }

        if (Guid.TryParse(s, out var g))
        {
            return g.ToString("D").ToUpperInvariant();
        }

        return s;
    }
}

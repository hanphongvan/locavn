namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Services;

internal static class StoreAdminInventoryMapValidator
{
    private static readonly HashSet<string> Allowed = new(StringComparer.OrdinalIgnoreCase) { "XANG", "DAU" };

    public static string? ValidateGroupCode(string? groupCode)
    {
        if (string.IsNullOrWhiteSpace(groupCode))
            return "groupCode is required (XANG or DAU).";
        return Allowed.Contains(groupCode.Trim()) ? null : "groupCode must be XANG or DAU.";
    }

    public static string? NormalizeGroupCode(string? groupCode) =>
        string.IsNullOrWhiteSpace(groupCode) ? null : groupCode.Trim().ToUpperInvariant();
}

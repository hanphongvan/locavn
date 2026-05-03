namespace Httm.XangDau.Api.Features.Admin.Auth.Services;

/// <summary>Maps <c>AspNetUsers.Loai</c> to stable admin app role names (Angular RBAC).</summary>
public static class AdminPortalLoaiRoleMapper
{
    public const string Admin = "ADMIN";
    public const string Trader = "TRADER";
    public const string Store = "STORE";

    public const int LoaiAdmin = 1;
    public const int LoaiTrader = 3;
    public const int LoaiStore = 4;

    /// <summary>Self-registered / general portal user (mobile consumer shell; no admin RBAC).</summary>
    public const int LoaiPortalUser = 5;

    public const string PortalUser = "PORTAL_USER";

    public static string? MapRole(int? loai) =>
        loai switch
        {
            LoaiAdmin => Admin,
            LoaiTrader => Trader,
            LoaiStore => Store,
            LoaiPortalUser => PortalUser,
            _ => null,
        };

    public static bool IsFullSystemScope(int? loai) => loai == LoaiAdmin;
}

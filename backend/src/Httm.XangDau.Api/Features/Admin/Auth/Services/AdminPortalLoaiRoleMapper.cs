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

    /// <summary>Reserved HTTM domain — checklist docs/modules/httm.</summary>
    public const int LoaiHttmAdmin = 10;

    public const int LoaiBctStaff = 11;
    public const int LoaiSoStaff = 12;
    public const int LoaiUnitUser = 13;

    public const string PortalUser = "PORTAL_USER";

    public const string HttmAdmin = "HTTM_ADMIN";
    public const string BctStaff = "BCT_STAFF";
    public const string SoStaff = "SO_STAFF";
    public const string UnitUser = "UNIT_USER";

    public static string? MapRole(int? loai) =>
        loai switch
        {
            LoaiAdmin => Admin,
            LoaiTrader => Trader,
            LoaiStore => Store,
            LoaiPortalUser => PortalUser,
            LoaiHttmAdmin => HttmAdmin,
            LoaiBctStaff => BctStaff,
            LoaiSoStaff => SoStaff,
            LoaiUnitUser => UnitUser,
            _ => null,
        };

    public static bool IsFullSystemScope(int? loai) => loai == LoaiAdmin;

    /// <summary>Toàn quốc cho nghiệp vụ HTTM (đọc dữ liệu nhạy cảm, không giới hạn tỉnh).</summary>
    public static bool IsHttmNationalScope(int? loai) =>
        loai is LoaiAdmin or LoaiHttmAdmin or LoaiBctStaff;

    /// <summary>Được gọi API quản lý HTTM (đọc/ghi theo policy từng endpoint).</summary>
    public static bool CanUseHttmModule(int? loai, bool isMachineFullAccess) =>
        isMachineFullAccess
        || loai is LoaiAdmin or LoaiHttmAdmin or LoaiBctStaff or LoaiSoStaff;

    /// <summary>Phiếu khảo sát — thêm đơn vị được khảo sát (<see cref="LoaiUnitUser"/>).</summary>
    public static bool CanUseSurveyModule(int? loai, bool isMachineFullAccess) =>
        isMachineFullAccess
        || loai is LoaiAdmin or LoaiHttmAdmin or LoaiBctStaff or LoaiSoStaff or LoaiUnitUser;
}

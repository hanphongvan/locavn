using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>Store admin: đơn vị phải là cửa hàng xăng dầu bán lẻ — <c>DM_DonVi.CapDonViId</c> = 248 (cùng <see cref="PetrolRetailConstants.CapDonViId"/>).</summary>
public static class StoreAdminAccessRules
{
    public const int RequiredCapDonViId = PetrolRetailConstants.CapDonViId;
}

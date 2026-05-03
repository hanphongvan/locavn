using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices;

/// <summary>Server-defined catalog entries for the mobile service picker (not per-store mock data).</summary>
public static class StoreServiceCatalog
{
    private static readonly IReadOnlyList<StoreAdminStoreServiceCatalogItemDto> Items =
    [
        new("RESTROOM", "Nhà vệ sinh", "wc", false),
        new("CAR_WASH", "Rửa xe", "local_car_wash", true),
        new("CONVENIENCE", "Cửa hàng tiện lợi", "storefront", false),
        new("OIL_CHANGE", "Thay nhớt", "oil_barrel", true),
        new("TIRE_AIR", "Bơm lốp", "tire_repair", true),
        new("ATM", "ATM", "atm", false),
        new("PARKING", "Bãi đỗ xe", "local_parking", true),
        new("WIFI", "WiFi miễn phí", "wifi", false),
        new("FOOD_DRINK", "Ăn uống", "restaurant", false),
        new("EV_CHARGING", "Sạc xe điện", "ev_station", true),
        new("REST_AREA", "Khu nghỉ", "chair", false),
    ];

    public static IReadOnlyList<StoreAdminStoreServiceCatalogItemDto> All => Items;

    public static StoreAdminStoreServiceCatalogItemDto? FindByCode(string serviceCode)
    {
        if (string.IsNullOrWhiteSpace(serviceCode))
            return null;
        var key = serviceCode.Trim().ToUpperInvariant();
        foreach (var x in Items)
        {
            if (string.Equals(x.ServiceCode, key, StringComparison.Ordinal))
                return x;
        }

        return null;
    }
}

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;

/// <summary>Admin view of <c>DM_DonVi</c> for petrol stores (<c>CapDonViId</c> = <c>PetrolRetailConstants.CapDonViId</c>).</summary>
public sealed record StoreAdminStoreDto(
    int Id,
    string Ma,
    string Ten,
    string? DienThoai,
    string? DiaChi,
    string? Email,
    bool? TrangThai,
    int? Tinh,
    int? Xa,
    string? DiaChiChiTiet,
    decimal? ViDo,
    decimal? KinhDo,
    TimeOnly? OpenTime,
    TimeOnly? CloseTime);

public sealed record StoreAdminStoreListPageDto(
    IReadOnlyList<StoreAdminStoreDto> Items,
    int TotalCount,
    int Skip,
    int Take);

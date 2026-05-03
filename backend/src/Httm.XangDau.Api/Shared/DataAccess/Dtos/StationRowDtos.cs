namespace Httm.XangDau.Api.Shared.DataAccess.Dtos;

/// <summary>Read model for <c>DM_DonVi</c> (persistence DTO, not an API contract).</summary>
public sealed record DonViRowDto(
    int Id,
    string Ma,
    string Ten,
    int CapDonViId,
    int? Tinh,
    int? Xa,
    string? DiaChi,
    string? DiaChiChiTiet,
    string? DienThoai,
    string? Email,
    string? SoGiayPhep,
    DateTime? NgayCap,
    DateTime? NgayHetHan,
    decimal? ViDo,
    decimal? KinhDo,
    bool? TrangThai);

namespace Httm.XangDau.Api.Shared.DataAccess.Dtos;

public sealed record KieuKyBaoCaoRowDto(int Id, string? Ma, string Ten, int? SapXep);

public sealed record QtTkThongKeRowDto(
    Guid Id,
    DateOnly? TuNgay,
    DateOnly DenNgay,
    int? DonViCap1,
    int Loai,
    int? KieuKyBaoCao,
    int? TrangThai,
    DateTime? ThoiGianGui);

public sealed record QtTkThongKeChiTietRowDto(
    Guid Id,
    Guid ThongKeId,
    string? MaSo,
    string? TenThongKe,
    int? LoaiGia,
    DateTime? ThoiDiemDinhGia,
    decimal? So_01,
    decimal? So_02,
    decimal? So_03,
    int? ThuTu,
    int? Xoa);

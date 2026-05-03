namespace Httm.XangDau.Api.Shared.DataAccess.Dtos;

public sealed record KhoXangDauRowDto(
    Guid Id,
    int? DonViId,
    string? TenKho,
    int? Tinh,
    int? Xa,
    string? DiaChiChiTiet,
    decimal? TongDungTich,
    int? LoaiKho,
    string? GhiChu);

public sealed record PhanBoDungTichRowDto(
    Guid Id,
    Guid? KhoId,
    int? HinhThuc,
    int? ThuongNhanThueId,
    decimal? TongDungTich,
    DateOnly? NgayBatDau,
    DateOnly? NgayKetThuc,
    int? TrangThai,
    string? GhiChu);

public sealed record TonKhoRowDto(
    Guid Id,
    Guid? PhanBoId,
    DateTime? Ngay,
    decimal? SoLuong,
    int? HeSo,
    string? GhiChu);

public sealed record HopDongKhoRowDto(
    Guid Id,
    Guid? PhanBoId,
    string? SoHopDong,
    DateOnly? NgayBatDau,
    DateOnly? NgayKetThuc,
    string? GhiChu);

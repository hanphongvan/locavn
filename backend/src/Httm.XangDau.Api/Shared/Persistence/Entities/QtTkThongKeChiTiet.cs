namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>QT_TK_ThongKeChiTiet</c>.</summary>
public sealed class QtTkThongKeChiTiet
{
    public Guid Id { get; set; }
    public Guid ThongKeId { get; set; }
    public int? Nhom { get; set; }
    public int? ThiTruongId { get; set; }
    public string? ThiTruong { get; set; }
    public int? NhaCungCapId { get; set; }
    public Guid? ChiTieuThongKeId { get; set; }
    public string? MaSo { get; set; }
    public string? TenThongKe { get; set; }
    public string? GhiChu { get; set; }
    public int? ThuTu { get; set; }
    public Guid? ChaId { get; set; }
    public string? MaAo { get; set; }
    public int? InDam { get; set; }
    public decimal? So_01 { get; set; }
    public decimal? So_02 { get; set; }
    public decimal? So_03 { get; set; }
    public decimal? So_04 { get; set; }
    public decimal? So_05 { get; set; }
    public decimal? So_06 { get; set; }
    public decimal? So_07 { get; set; }
    public decimal? So_08 { get; set; }
    public decimal? So_09 { get; set; }
    public decimal? So_10 { get; set; }
    public decimal? So_11 { get; set; }
    public decimal? So_12 { get; set; }
    public decimal? So_13 { get; set; }
    public decimal? So_14 { get; set; }
    public decimal? So_15 { get; set; }
    public decimal? So_16 { get; set; }
    public decimal? So_17 { get; set; }
    public decimal? So_18 { get; set; }
    public decimal? So_19 { get; set; }
    public decimal? So_20 { get; set; }
    public decimal? So_21 { get; set; }
    public decimal? So_22 { get; set; }
    public decimal? So_23 { get; set; }
    public decimal? So_24 { get; set; }
    public decimal? So_25 { get; set; }
    public string? GiayPhep_So { get; set; }
    public DateTime? GiayPhep_NgayCap { get; set; }
    public int? LoaiGia { get; set; }
    public DateTime? ThoiDiemDinhGia { get; set; }
    public int? DonViTinhId { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public int? Xoa { get; set; }

    public QtTkThongKe? ThongKe { get; set; }
    public TkChiTieuBaoCao? ChiTieuThongKe { get; set; }
}

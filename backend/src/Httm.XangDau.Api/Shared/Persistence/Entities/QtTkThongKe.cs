namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>QT_TK_ThongKe</c>.</summary>
public sealed class QtTkThongKe
{
    public Guid Id { get; set; }
    public DateOnly? TuNgay { get; set; }
    public DateOnly DenNgay { get; set; }
    public int? DonViCap1 { get; set; }
    public int? DonViCap2 { get; set; }
    public string? CanBoLap { get; set; }
    public string? ThuTruongDonVi { get; set; }
    public Guid? BaoCaoId { get; set; }
    public int? ThangQuy { get; set; }
    public int Loai { get; set; }
    public bool? Chot { get; set; }
    public int? KieuKyBaoCao { get; set; }
    public int? TrangThai { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public DateTime? ThoiHanTuNgay { get; set; }
    public DateTime? ThoiHanDenNgay { get; set; }
    public int? DonViGiao { get; set; }
    public int? FileAtach { get; set; }
    public int? Xoa { get; set; }
    public Guid? BaoCaoCuId { get; set; }
    public DateTime? ThoiGianGui { get; set; }

    public ICollection<QtTkThongKeChiTiet> ChiTiets { get; set; } = new List<QtTkThongKeChiTiet>();
}

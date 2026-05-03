namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_GiaoBaoCao</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class TkGiaoBaoCao
{
    public Guid Id { get; set; }
    public int? DonViGiaoId { get; set; }
    public Guid? BaoCaoId { get; set; }
    public int? KieuKyBaoCao { get; set; }
    public DateTime? NgayBatDauKyBc { get; set; }
    public DateTime? NgayKetThucKyBc { get; set; }
    public DateTime? TuNgay { get; set; }
    public DateTime? DenNgay { get; set; }
    public int? Nam { get; set; }
    public int? ThangQuy { get; set; }
    public DateTime? NgayMo { get; set; }
    public DateTime? NgayDong { get; set; }
    public bool? TuDongGiao { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
}

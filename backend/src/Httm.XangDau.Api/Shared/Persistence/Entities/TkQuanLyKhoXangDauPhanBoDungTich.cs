namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_QuanLyKhoXangDau_PhanBoDungTich</c>.</summary>
public sealed class TkQuanLyKhoXangDauPhanBoDungTich
{
    public Guid Id { get; set; }
    public Guid? KhoId { get; set; }
    public int? HinhThuc { get; set; }
    public int? ThuongNhanThueId { get; set; }
    public string? BonBe { get; set; }
    public decimal? TongDungTich { get; set; }
    public DateOnly? NgayBatDau { get; set; }
    public DateOnly? NgayKetThuc { get; set; }
    public int? TrangThai { get; set; }
    public string? GhiChu { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public TkQuanLyKhoXangDau? Kho { get; set; }
    public ICollection<TkQuanLyKhoXangDauTonKho> TonKhos { get; set; } = new List<TkQuanLyKhoXangDauTonKho>();
}

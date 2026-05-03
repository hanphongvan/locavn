namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_QuanLyKhoXangDau_TonKho</c>.</summary>
public sealed class TkQuanLyKhoXangDauTonKho
{
    public Guid Id { get; set; }
    public Guid? PhanBoId { get; set; }
    public DateTime? Ngay { get; set; }
    public decimal? SoLuong { get; set; }
    public int? HeSo { get; set; }
    public string? GhiChu { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public TkQuanLyKhoXangDauPhanBoDungTich? PhanBo { get; set; }
}

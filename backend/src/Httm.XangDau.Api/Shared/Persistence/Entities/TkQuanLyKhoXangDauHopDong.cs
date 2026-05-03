namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_QuanLyKhoXangDau_HopDong</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class TkQuanLyKhoXangDauHopDong
{
    public Guid Id { get; set; }
    public Guid? PhanBoId { get; set; }
    public string? SoHopDong { get; set; }
    public DateOnly? NgayBatDau { get; set; }
    public DateOnly? NgayKetThuc { get; set; }
    public string? GhiChu { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public TkQuanLyKhoXangDauPhanBoDungTich? PhanBo { get; set; }
}

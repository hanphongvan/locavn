namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_QuanLyKhoXangDau</c>.</summary>
public sealed class TkQuanLyKhoXangDau
{
    public Guid Id { get; set; }
    public int? DonViId { get; set; }
    public string? TenKho { get; set; }
    public int? Tinh { get; set; }
    public int? Xa { get; set; }
    public string? DiaChiChiTiet { get; set; }
    public decimal? TongDungTich { get; set; }
    public int? LoaiKho { get; set; }
    public string? TenDonViSoHuu { get; set; }
    public int? DonViNgoai { get; set; }
    public string? GhiChu { get; set; }
    public int? SapXep { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public ICollection<TkQuanLyKhoXangDauPhanBoDungTich> PhanBoDungTiches { get; set; } = new List<TkQuanLyKhoXangDauPhanBoDungTich>();
}

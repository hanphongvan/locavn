namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_QuanLyGiayPhep</c>.</summary>
public sealed class TkQuanLyGiayPhep
{
    public Guid Id { get; set; }
    public int? DonViCapId { get; set; }
    public int? DonViId { get; set; }
    /// <summary>Column <c>DonVi</c> (display text in schema).</summary>
    public string? DonViTen { get; set; }
    public string? SoGiayPhep { get; set; }
    public DateTime? NgayCap { get; set; }
    public DateTime? NgayHetHan { get; set; }
    public int? Loai { get; set; }
    public int? LoaiGiayPhepId { get; set; }
    public string? GhiChu { get; set; }
    public DateTime? NgayThuHoi { get; set; }
    public string? LyDoThuHoi { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
}

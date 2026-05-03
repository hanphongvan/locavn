namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_ChiTieuBaoCao</c>.</summary>
public sealed class TkChiTieuBaoCao
{
    public Guid Id { get; set; }
    public int? IdChiTieu { get; set; }
    public string? MaReport { get; set; }
    public string? MaStt { get; set; }
    public string? Ma { get; set; }
    public string? Ten { get; set; }
    public string? CongMaSo { get; set; }
    public int? IndexOrder { get; set; }
    public int? RecordType { get; set; }
    public int? IdStyle { get; set; }
    public int? IdNhom { get; set; }
    public int? Stt { get; set; }
    public string? QuyetDinh { get; set; }
    public string? TheoThongTu { get; set; }
    public int? ChuDam { get; set; }
    public string? TenSql { get; set; }
    public string? TenNgoaiNgu { get; set; }
    public Guid? Parent { get; set; }
    public int? Cap { get; set; }
    public int? CoCapCon { get; set; }
    public string? MaAo { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public byte[]? Versions { get; set; }
    public string? CongMaSo2 { get; set; }
    public int? HienThi { get; set; }
    public int? DonViTinhId { get; set; }
    public int? DonViTinh05Id { get; set; }
    public int? DonViTinh02Id { get; set; }
}

namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>TK_GiaoBaoCaoChiTiet</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class TkGiaoBaoCaoChiTiet
{
    public Guid Id { get; set; }
    public Guid? GiaoBaoCaoId { get; set; }
    public int? DonViId { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public TkGiaoBaoCao? GiaoBaoCao { get; set; }
}

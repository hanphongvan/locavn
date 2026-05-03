namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>QT_TK_ChotSoLieu</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class QtTkChotSoLieu
{
    public Guid Id { get; set; }
    public int? Nam { get; set; }
    public DateTime? NgayChot { get; set; }
    public int? DonViCap1 { get; set; }
    public int? LoaiBaoCao { get; set; }
    public Guid? BaoCaoId { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
}

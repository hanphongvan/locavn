namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>DM_KieuKyBaoCao</c> — reporting period type metadata (see <c>docs/architecture/database.md</c> appendix).</summary>
public sealed class DmKieuKyBaoCao
{
    public int Id { get; set; }
    public string? Ma { get; set; }
    public string Ten { get; set; } = null!;
    public int? TenantId { get; set; }
    public int? Parent { get; set; }
    public int? Category { get; set; }
    public int? SapXep { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
}

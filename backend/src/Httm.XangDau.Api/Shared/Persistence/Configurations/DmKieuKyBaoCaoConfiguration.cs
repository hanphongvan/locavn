using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class DmKieuKyBaoCaoConfiguration : IEntityTypeConfiguration<DmKieuKyBaoCao>
{
    public void Configure(EntityTypeBuilder<DmKieuKyBaoCao> b)
    {
        // Documented in docs/architecture/database.md appendix (column names as in source DB: tenantId, category, etc.).
        b.ToTable("DM_KieuKyBaoCao");
        b.HasKey(x => x.Id);

        b.Property(x => x.Ma).HasMaxLength(50);
        b.Property(x => x.Ten).HasMaxLength(300).IsRequired();
        b.Property(x => x.TenantId).HasColumnName("tenantId");
        b.Property(x => x.Parent).HasColumnName("Parent");
        b.Property(x => x.Category).HasColumnName("category");
        b.Property(x => x.CreatedBy).HasMaxLength(100);
        b.Property(x => x.ModifiedBy).HasMaxLength(100);

        // Parent is int? → DM_KieuKyBaoCao.Id (hierarchy). No navigation to avoid duplicate relationship graphs on read-only API.
    }
}

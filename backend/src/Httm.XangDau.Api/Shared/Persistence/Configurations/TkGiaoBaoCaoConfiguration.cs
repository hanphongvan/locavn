using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkGiaoBaoCaoConfiguration : IEntityTypeConfiguration<TkGiaoBaoCao>
{
    public void Configure(EntityTypeBuilder<TkGiaoBaoCao> b)
    {
        b.ToTable("TK_GiaoBaoCao");
        b.HasKey(x => x.Id);

        b.Property(x => x.NgayBatDauKyBc).HasColumnName("NgayBatDauKyBC");
        b.Property(x => x.NgayKetThucKyBc).HasColumnName("NgayKetThucKyBC");
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);
    }
}

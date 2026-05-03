using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationBadReportConfiguration : IEntityTypeConfiguration<StationBadReport>
{
    public void Configure(EntityTypeBuilder<StationBadReport> b)
    {
        b.ToTable("StationBadReports");
        b.HasKey(x => x.Id);

        b.Property(x => x.Content).HasMaxLength(8000).IsRequired();
        b.Property(x => x.CreatedAt).HasColumnType("datetime2");
        b.Property(x => x.Status).HasColumnType("tinyint");
        b.Property(x => x.ReporterUserId).HasMaxLength(128);

        b.HasIndex(x => x.StationId);
        b.HasIndex(x => new { x.CreatedAt, x.Id });
        b.HasIndex(x => new { x.ReporterUserId, x.CreatedAt });

        b.HasOne<AspNetUser>()
            .WithMany()
            .HasForeignKey(x => x.ReporterUserId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        b.HasOne<DmDonVi>()
            .WithMany()
            .HasForeignKey(x => x.StationId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationBadReportImageConfiguration : IEntityTypeConfiguration<StationBadReportImage>
{
    public void Configure(EntityTypeBuilder<StationBadReportImage> b)
    {
        b.ToTable("StationBadReportImages");
        b.HasKey(x => x.Id);

        b.Property(x => x.ImageUrl).HasMaxLength(2048).IsRequired();

        b.HasIndex(x => x.ReportId);

        b.HasOne(x => x.Report)
            .WithMany(r => r.Images)
            .HasForeignKey(x => x.ReportId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

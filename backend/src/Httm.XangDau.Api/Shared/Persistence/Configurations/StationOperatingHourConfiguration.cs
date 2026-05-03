using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationOperatingHourConfiguration : IEntityTypeConfiguration<StationOperatingHour>
{
    public void Configure(EntityTypeBuilder<StationOperatingHour> b)
    {
        b.ToTable("StationOperatingHours");
        b.HasKey(x => x.Id);

        b.Property(x => x.DayOfWeek).HasColumnName("DayOfWeek");
        b.Property(x => x.OpensAt).HasColumnType("time(0)");
        b.Property(x => x.ClosesAt).HasColumnType("time(0)");

        b.HasIndex(x => new { x.DonViId, x.DayOfWeek }).IsUnique();

        b.HasOne(x => x.DonVi)
            .WithMany(d => d.OperatingHours)
            .HasForeignKey(x => x.DonViId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

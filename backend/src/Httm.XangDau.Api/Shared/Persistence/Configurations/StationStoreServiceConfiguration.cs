using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationStoreServiceConfiguration : IEntityTypeConfiguration<StationStoreService>
{
    public void Configure(EntityTypeBuilder<StationStoreService> b)
    {
        b.ToTable("StationStoreServices");
        b.HasKey(x => x.Id);

        b.Property(x => x.ServiceCode).HasMaxLength(50).IsRequired();
        b.Property(x => x.DisplayName).HasMaxLength(200).IsRequired();
        b.Property(x => x.IconKey).HasMaxLength(50);
        b.Property(x => x.Price).HasPrecision(18, 2);

        b.HasIndex(x => new { x.DonViId, x.ServiceCode }).IsUnique();

        b.HasOne(x => x.DonVi)
            .WithMany(d => d.StoreServices)
            .HasForeignKey(x => x.DonViId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

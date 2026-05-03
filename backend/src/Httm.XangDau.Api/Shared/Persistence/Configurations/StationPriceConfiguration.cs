using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationPriceConfiguration : IEntityTypeConfiguration<StationPrice>
{
    public void Configure(EntityTypeBuilder<StationPrice> b)
    {
        b.ToTable("StationPrices");

        b.HasKey(x => x.Id);

        b.Property(x => x.ActiveDate).HasColumnType("datetime").IsRequired();
        b.Property(x => x.IsActive).IsRequired();
        b.Property(x => x.Created).HasColumnType("datetime").IsRequired();
        b.Property(x => x.Modified).HasColumnType("datetime").IsRequired();
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);
    }
}

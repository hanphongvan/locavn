using Httm.XangDau.Api.Shared.Persistence.Entities;

using Microsoft.EntityFrameworkCore;

using Microsoft.EntityFrameworkCore.Metadata.Builders;



namespace Httm.XangDau.Api.Shared.Persistence.Configurations;



public sealed class StationProductPriceConfiguration : IEntityTypeConfiguration<StationProductPrice>

{

    public void Configure(EntityTypeBuilder<StationProductPrice> b)

    {

        b.ToTable("StationProductPrices");

        b.HasKey(x => x.Id);

        b.Property(x => x.StationPricesId).IsRequired();

        b.HasOne(x => x.StationPrice)
            .WithMany(x => x.ProductPrices)
            .HasForeignKey(x => x.StationPricesId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Property(x => x.Price).HasPrecision(18, 2).IsRequired();

        b.Property(x => x.EffectiveDate).HasColumnType("datetime").IsRequired();

        b.Property(x => x.Note).HasMaxLength(500);

        b.Property(x => x.Created).HasColumnType("datetime").IsRequired();

        b.Property(x => x.Modified).HasColumnType("datetime").IsRequired();

        b.Property(x => x.CreatedBy).HasMaxLength(100);

        b.Property(x => x.ModifiedBy).HasMaxLength(100);



        b.HasIndex(x => new { x.DonViId, x.ProductId, x.EffectiveDate })

            .IsDescending(false, false, true);

    }

}



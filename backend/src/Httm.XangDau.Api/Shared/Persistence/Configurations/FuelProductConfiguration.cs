using Httm.XangDau.Api.Shared.Persistence.Entities;

using Microsoft.EntityFrameworkCore;

using Microsoft.EntityFrameworkCore.Metadata.Builders;



namespace Httm.XangDau.Api.Shared.Persistence.Configurations;



public sealed class FuelProductConfiguration : IEntityTypeConfiguration<FuelProduct>

{

    public void Configure(EntityTypeBuilder<FuelProduct> b)

    {

        b.ToTable("FuelProducts");

        b.HasKey(x => x.Id);



        b.Property(x => x.Code).HasMaxLength(50).IsRequired();

        b.Property(x => x.Name).HasMaxLength(200).IsRequired();

        b.Property(x => x.Description).HasMaxLength(500);

        b.Property(x => x.CreatedBy).HasMaxLength(100);

        b.Property(x => x.ModifiedBy).HasMaxLength(100);

        b.Property(x => x.Created).HasColumnType("datetime").IsRequired();

        b.Property(x => x.Modified).HasColumnType("datetime").IsRequired();



        b.HasIndex(x => x.Code).IsUnique();

    }

}



using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationReviewImageConfiguration : IEntityTypeConfiguration<StationReviewImage>
{
    public void Configure(EntityTypeBuilder<StationReviewImage> b)
    {
        b.ToTable("StationReviewImages");
        b.HasKey(x => x.Id);

        b.Property(x => x.ImageUrl).HasMaxLength(2048).IsRequired();

        b.HasIndex(x => x.ReviewId);

        b.HasOne(x => x.Review)
            .WithMany(r => r.Images)
            .HasForeignKey(x => x.ReviewId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

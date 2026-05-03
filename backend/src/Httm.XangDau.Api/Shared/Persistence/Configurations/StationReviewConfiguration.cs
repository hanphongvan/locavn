using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class StationReviewConfiguration : IEntityTypeConfiguration<StationReview>
{
    public void Configure(EntityTypeBuilder<StationReview> b)
    {
        b.ToTable("StationReviews");
        b.HasKey(x => x.Id);

        b.Property(x => x.Rating).HasColumnType("tinyint");
        b.Property(x => x.Comment).HasMaxLength(2000);
        b.Property(x => x.CreatedAt).HasColumnType("datetime2");
        b.Property(x => x.ReviewerUserId).HasMaxLength(128);

        b.HasIndex(x => x.StationId);
        b.HasIndex(x => new { x.StationId, x.CreatedAt });
        b.HasIndex(x => new { x.ReviewerUserId, x.CreatedAt });

        b.HasOne<AspNetUser>()
            .WithMany()
            .HasForeignKey(x => x.ReviewerUserId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        b.HasOne(x => x.Station)
            .WithMany(d => d.Reviews)
            .HasForeignKey(x => x.StationId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

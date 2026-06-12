using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AppFeedbackConfiguration : IEntityTypeConfiguration<AppFeedback>
{
    public void Configure(EntityTypeBuilder<AppFeedback> b)
    {
        b.ToTable("AppFeedbacks");
        b.HasKey(x => x.Id);

        b.Property(x => x.Content).HasMaxLength(8000).IsRequired();
        b.Property(x => x.Category).HasColumnType("tinyint");
        b.Property(x => x.Status).HasColumnType("tinyint");
        b.Property(x => x.UserId).HasMaxLength(128);
        b.Property(x => x.ContactEmail).HasMaxLength(256);
        b.Property(x => x.ContactPhone).HasMaxLength(32);
        b.Property(x => x.AppVersion).HasMaxLength(50);
        b.Property(x => x.Platform).HasMaxLength(20);
        b.Property(x => x.CreatedAt).HasColumnType("datetime2");

        b.HasIndex(x => new { x.CreatedAt, x.Id });
        b.HasIndex(x => new { x.UserId, x.CreatedAt });
        b.HasIndex(x => x.Category);
        b.HasIndex(x => x.Status);

        b.HasOne<AspNetUser>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        b.HasMany(x => x.Images)
            .WithOne(i => i.Feedback!)
            .HasForeignKey(i => i.FeedbackId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

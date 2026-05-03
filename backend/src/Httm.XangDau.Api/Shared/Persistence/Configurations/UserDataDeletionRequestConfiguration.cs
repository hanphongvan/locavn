using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class UserDataDeletionRequestConfiguration : IEntityTypeConfiguration<UserDataDeletionRequest>
{
    public void Configure(EntityTypeBuilder<UserDataDeletionRequest> b)
    {
        b.ToTable("UserDataDeletionRequests");

        b.HasKey(x => x.Id);
        b.Property(x => x.Id).ValueGeneratedOnAdd();

        b.Property(x => x.UserId).HasMaxLength(128).IsRequired();
        b.Property(x => x.RequestType).HasMaxLength(100).IsRequired();
        b.Property(x => x.Scope).HasMaxLength(50).IsRequired();
        b.Property(x => x.Note).HasMaxLength(2000);
        b.Property(x => x.Status).HasMaxLength(32).IsRequired();
        b.Property(x => x.RequestedAt).IsRequired();
        b.Property(x => x.ProcessedBy).HasMaxLength(128);

        b.HasIndex(x => new { x.UserId, x.Status })
            .HasDatabaseName("IX_UserDataDeletionRequests_UserId_Status");

        b.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

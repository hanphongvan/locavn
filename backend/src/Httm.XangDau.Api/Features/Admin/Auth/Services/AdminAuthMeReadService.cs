using Httm.XangDau.Api.Features.Admin.Auth.Contracts;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Admin.Auth.Services;

/// <summary>Resolves general admin profile from portal user id + database (read-only).</summary>
public sealed class AdminAuthMeReadService(DmpPortalDbContext db)
{
    public async Task<AdminAuthMeDto?> GetMeByUserIdAsync(string userId, CancellationToken cancellationToken = default)
    {
        var row = await db.AspNetUsers.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.UserName, u.DisplayName, u.Email, u.DonViId, u.Loai })
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
            return null;

        AdminAuthMeOrganizationDto? org = null;
        if (row.DonViId is { } dvId)
        {
            var donVi = await db.DmDonVis.AsNoTracking()
                .Where(d => d.Id == dvId)
                .Select(d => new
                {
                    d.Id,
                    d.Ma,
                    d.Ten,
                    d.CapDonViId,
                    d.CapTrenId,
                    d.PhanLoaiId,
                    d.LoaiHinh,
                })
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false);

            if (donVi is not null)
            {
                org = new AdminAuthMeOrganizationDto(
                    donVi.Id,
                    donVi.Ma,
                    donVi.Ten,
                    donVi.CapDonViId,
                    donVi.CapTrenId,
                    donVi.PhanLoaiId,
                    donVi.LoaiHinh,
                    donVi.CapDonViId == PetrolRetailConstants.CapDonViId);
            }
        }

        var role = AdminPortalLoaiRoleMapper.MapRole(row.Loai);
        var fullSystem = AdminPortalLoaiRoleMapper.IsFullSystemScope(row.Loai);

        return new AdminAuthMeDto(
            row.UserName,
            row.DisplayName,
            row.Email,
            row.DonViId,
            row.Loai,
            role,
            fullSystem,
            org);
    }
}

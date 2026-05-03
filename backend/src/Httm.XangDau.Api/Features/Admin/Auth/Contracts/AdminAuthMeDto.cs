using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Features.Admin.Auth.Contracts;

/// <summary>Lightweight portal user bootstrap from Bearer JWT + <c>AspNetUsers</c> / <c>DM_DonVi</c> (no password logic).</summary>
public sealed record AdminAuthMeDto(
    string UserName,
    string? DisplayName,
    string? Email,
    /// <summary><c>AspNetUsers.DonViId</c> — organization / store / trader context when set.</summary>
    int? DonViId,
    /// <summary><c>AspNetUsers.Loai</c> — drives <see cref="Role"/>.</summary>
    int? Loai,
    /// <summary>Mapped from <see cref="Loai"/>: <c>ADMIN</c>, <c>TRADER</c>, <c>STORE</c>; <see langword="null"/> when unknown.</summary>
    string? Role,
    /// <summary><see langword="true"/> when <see cref="Loai"/> is admin (<c>1</c>) — client may treat as full system scope.</summary>
    bool FullSystemScope,
    /// <summary>Row from <c>DM_DonVi</c> for <see cref="DonViId"/> when present and found.</summary>
    AdminAuthMeOrganizationDto? Organization);

/// <summary>Subset of <c>DM_DonVi</c> for admin app initialization.</summary>
public sealed record AdminAuthMeOrganizationDto(
    int Id,
    string Ma,
    string Ten,
    int CapDonViId,
    int? CapTrenId,
    int? PhanLoaiId,
    int? LoaiHinh,
    /// <summary><see langword="true"/> when <see cref="CapDonViId"/> matches petrol retail store cap (<see cref="PetrolRetailConstants.CapDonViId"/>).</summary>
    bool IsPetrolRetailStore);

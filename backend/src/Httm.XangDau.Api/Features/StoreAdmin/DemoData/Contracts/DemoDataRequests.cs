namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Contracts;

/// <summary>
/// Body for all demo-data commands. Maps to stored procedure parameters <c>@Tinh</c>, <c>@DaysBack</c> (from <see cref="Days"/>), <c>@ClearOldData</c>.
/// <c>sp_Demo_ClearData</c> only uses <c>@Tinh</c>; <see cref="Days"/> and <see cref="ClearOldData"/> are accepted for a uniform client contract but not passed to that procedure.
/// </summary>
public sealed record DemoDataCommandRequest(int Tinh, int Days, bool ClearOldData);

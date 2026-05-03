namespace Httm.XangDau.Api.Shared.Common;

/// <summary>Uniform payload for phase-1 endpoints that are not yet backed by queries.</summary>
public sealed record Phase1ScaffoldResponse(string Feature, string Message, string DocumentationHint);

namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Contracts;

/// <summary>Result of a demo-data stored procedure execution (JSON camelCase: <c>success</c>, <c>message</c>, <c>utcCompleted</c>).</summary>
public sealed record DemoDataOperationResponse(bool Success, string? Message, DateTimeOffset UtcCompleted);

namespace Httm.XangDau.Api.Features.Account.Contracts;

public sealed class RequestDeletePersonalDataBody
{
    public string? RequestType { get; set; }

    public string? Scope { get; set; }

    public string? Note { get; set; }
}

public sealed class RequestDeletePersonalDataResponse
{
    public bool Success { get; set; }

    public string Message { get; set; } = string.Empty;
}

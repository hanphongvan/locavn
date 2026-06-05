using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Shared.Middleware;

internal sealed class GlobalExceptionHandler(
    ILogger<GlobalExceptionHandler> logger,
    IHostEnvironment environment) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        // Client tự hủy request (đóng tab, F5, Angular takeUntilDestroyed unsubscribe → abort XHR)
        // → OperationCanceledException/TaskCanceledException. KHÔNG phải lỗi server: log mức thông tin,
        // trả 499 (Client Closed Request) và KHÔNG ghi body vì client đã ngắt kết nối.
        if (exception is OperationCanceledException && httpContext.RequestAborted.IsCancellationRequested)
        {
            logger.LogInformation("Request bị client hủy: {Method} {Path}",
                httpContext.Request.Method, httpContext.Request.Path);
            if (!httpContext.Response.HasStarted)
                httpContext.Response.StatusCode = 499;
            return true;
        }

        logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);

        var problem = new ProblemDetails
        {
            Title = "An unexpected error occurred.",
            Status = StatusCodes.Status500InternalServerError,
            Type = "https://httpstatuses.com/500",
            Detail = environment.IsDevelopment() ? exception.ToString() : null
        };

        httpContext.Response.StatusCode = problem.Status.Value;
        await httpContext.Response.WriteAsJsonAsync(problem, cancellationToken);
        return true;
    }
}

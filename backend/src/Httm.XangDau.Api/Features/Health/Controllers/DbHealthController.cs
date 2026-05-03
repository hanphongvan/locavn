using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Health.Controllers;

[ApiController]
[Route("api/health")]
[Tags("Health")]
public sealed class DbHealthController(DmpPortalDbContext db) : ControllerBase
{
    /// <summary>Verifies that the configured SQL Server connection can be opened.</summary>
    [HttpGet("db")]
    [ProducesResponseType(typeof(DbHealthOkResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(DbHealthErrorResponse), StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> Database(CancellationToken cancellationToken)
    {
        try
        {
            var ok = await db.Database.CanConnectAsync(cancellationToken);
            if (!ok)
            {
                return StatusCode(
                    StatusCodes.Status503ServiceUnavailable,
                    new DbHealthErrorResponse("unhealthy", "Cannot connect to the database."));
            }

            return Ok(new DbHealthOkResponse("healthy", "DMPPortal", DateTime.UtcNow));
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new DbHealthErrorResponse("unhealthy", ex.Message));
        }
    }
}

public sealed record DbHealthOkResponse(string Status, string Database, DateTime UtcCheckedAt);

public sealed record DbHealthErrorResponse(string Status, string Detail);

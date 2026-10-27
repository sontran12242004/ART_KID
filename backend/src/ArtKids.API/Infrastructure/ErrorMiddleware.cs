using System.Data.Common;
using ArtKids.BLL.Common;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.API.Infrastructure;

public sealed class ErrorMiddleware(RequestDelegate next, ILogger<ErrorMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
        {
            context.Response.StatusCode = 499;
        }
        catch (Exception error)
        {
            var status = error switch
            {
                BusinessException b => b.Status,
                DbUpdateException => 409,
                DbException => 409,
                _ => 500,
            };
            var detail =
                error is BusinessException ? error.Message
                : status == 409
                    ? "A conflicting update was detected. Refresh the data and retry the request."
                : "An unexpected error occurred.";
            if (status == 500)
                logger.LogError(
                    error,
                    "Unhandled request error {TraceId}",
                    context.TraceIdentifier
                );
            else if (status == 409)
                logger.LogDebug(error, "Transaction conflict");
            if (context.Response.HasStarted)
                throw;
            context.Response.StatusCode = status;
            await context.Response.WriteAsJsonAsync(
                new ProblemDetails
                {
                    Status = status,
                    Title = detail,
                    Extensions = { ["traceId"] = context.TraceIdentifier },
                }
            );
        }
    }
}

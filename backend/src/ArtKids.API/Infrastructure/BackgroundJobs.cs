using ArtKids.BLL.Services;

namespace ArtKids.API.Infrastructure;

public sealed class BackgroundJobs(IServiceScopeFactory scopes, ILogger<BackgroundJobs> logger)
    : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(2));
        var ticks = 0;
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    using var scope = scopes.CreateScope();
                    var ai = scope.ServiceProvider.GetRequiredService<AiService>();
                    await ai.ProcessOne(stoppingToken);
                    if (ticks++ % 30 == 0)
                    {
                        await ai.RecoverInterruptedJobs();
                        await scope
                            .ServiceProvider.GetRequiredService<CommerceService>()
                            .ExpireReservations();
                    }
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Background job will retry on next tick.");
                }
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { }
    }
}

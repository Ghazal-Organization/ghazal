using Azure.Monitor.OpenTelemetry.Exporter;
using Ghazal.Api.Configuration;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Resources;

var builder = FunctionsApplication.CreateBuilder(args);
builder.ConfigureFunctionsWebApplication();

var telemetry = TelemetryConfig.FromHost(builder.Configuration, builder.Environment);

var otel = builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r
        .AddService(serviceName: ApiConstants.ServiceName, serviceVersion: TelemetryConfig.ServiceVersion)
        .AddAttributes(new KeyValuePair<string, object>[]
        {
            new("deployment.environment", telemetry.Environment)
        }))
    .UseFunctionsWorkerDefaults();

if (telemetry.IsEnabled)
{
    otel.UseAzureMonitorExporter();
}

var app = builder.Build();

var startupLogger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Startup");
if (telemetry.IsEnabled)
{
    startupLogger.LogInformation(
        "App Insights enabled. service={Service} version={Version} env={Env}",
        ApiConstants.ServiceName, TelemetryConfig.ServiceVersion, telemetry.Environment);
}
else if (builder.Environment.IsDevelopment())
{
    startupLogger.LogWarning(
        "App Insights disabled (no connection string). service={Service} version={Version} env={Env}",
        ApiConstants.ServiceName, TelemetryConfig.ServiceVersion, telemetry.Environment);
}
else
{
    throw new InvalidOperationException(
        $"{ApiConstants.ApplicationInsightsConnectionStringKey} is required outside the Development environment.");
}

app.Run();
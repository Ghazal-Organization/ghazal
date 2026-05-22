using System.Reflection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace Ghazal.Api.Configuration;

internal sealed record TelemetryConfig(string? ConnectionString, string Environment)
{
    public bool IsEnabled = !string.IsNullOrWhiteSpace(ConnectionString);

    // Build version is resolved once per process - used as service.version
    // by OpenTelemetry and surfaced by /health for ops verification.
    public static readonly string ServiceVersion = Assembly.GetExecutingAssembly()
        .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion
        ?? Assembly.GetExecutingAssembly().GetName().Version?.ToString()
        ?? "0.0.0";
    
    public static TelemetryConfig FromHost(IConfiguration config, IHostEnvironment environment) => new(
        ConnectionString: config[ApiConstants.ApplicationInsightsConnectionStringKey],
        Environment: environment.EnvironmentName);
}
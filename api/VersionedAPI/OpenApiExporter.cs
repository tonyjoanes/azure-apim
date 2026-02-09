using Asp.Versioning.ApiExplorer;
using Microsoft.OpenApi.Writers;
using Swashbuckle.AspNetCore.Swagger;

namespace VersionedAPI;

/// <summary>
/// Exports OpenAPI specifications to files during build or deployment.
/// This allows APIM to import from files instead of requiring a running API endpoint.
/// </summary>
public class OpenApiExporter
{
    private readonly ISwaggerProvider _swaggerProvider;
    private readonly IApiVersionDescriptionProvider _apiVersionDescriptionProvider;

    public OpenApiExporter(
        ISwaggerProvider swaggerProvider,
        IApiVersionDescriptionProvider apiVersionDescriptionProvider)
    {
        _swaggerProvider = swaggerProvider;
        _apiVersionDescriptionProvider = apiVersionDescriptionProvider;
    }

    /// <summary>
    /// Exports all API version OpenAPI specs to the specified directory.
    /// </summary>
    /// <param name="outputDirectory">Directory to save OpenAPI spec files</param>
    /// <returns>List of exported file paths</returns>
    public async Task<List<string>> ExportAllVersionsAsync(string outputDirectory)
    {
        var exportedFiles = new List<string>();

        // Create output directory if it doesn't exist
        Directory.CreateDirectory(outputDirectory);

        foreach (var description in _apiVersionDescriptionProvider.ApiVersionDescriptions)
        {
            var filePath = await ExportVersionAsync(description.GroupName, outputDirectory);
            exportedFiles.Add(filePath);
        }

        return exportedFiles;
    }

    /// <summary>
    /// Exports a specific API version OpenAPI spec to a file.
    /// </summary>
    /// <param name="documentName">Version group name (e.g., "v1", "v2")</param>
    /// <param name="outputDirectory">Directory to save the file</param>
    /// <returns>Path to the exported file</returns>
    public async Task<string> ExportVersionAsync(string documentName, string outputDirectory)
    {
        // Generate the OpenAPI document
        var swagger = _swaggerProvider.GetSwagger(documentName);

        // Create filename: products-api-v1.json
        var fileName = $"versioned-api-{documentName}.json";
        var filePath = Path.Combine(outputDirectory, fileName);

        // Write to file
        await using var fileStream = File.Create(filePath);
        await using var streamWriter = new StreamWriter(fileStream);
        var jsonWriter = new OpenApiJsonWriter(streamWriter);

        swagger.SerializeAsV3(jsonWriter);
        await streamWriter.FlushAsync();

        Console.WriteLine($"✅ Exported OpenAPI spec: {filePath}");
        return filePath;
    }

    /// <summary>
    /// Exports OpenAPI specs with custom naming pattern.
    /// </summary>
    /// <param name="outputDirectory">Directory to save files</param>
    /// <param name="apiName">API name for file naming (e.g., "products-api")</param>
    /// <returns>Dictionary of version -> file path</returns>
    public async Task<Dictionary<string, string>> ExportWithCustomNamingAsync(
        string outputDirectory,
        string apiName)
    {
        var exportedFiles = new Dictionary<string, string>();
        Directory.CreateDirectory(outputDirectory);

        foreach (var description in _apiVersionDescriptionProvider.ApiVersionDescriptions)
        {
            var swagger = _swaggerProvider.GetSwagger(description.GroupName);
            var fileName = $"{apiName}-{description.GroupName}.json";
            var filePath = Path.Combine(outputDirectory, fileName);

            await using var fileStream = File.Create(filePath);
            await using var streamWriter = new StreamWriter(fileStream);
            var jsonWriter = new OpenApiJsonWriter(streamWriter);

            swagger.SerializeAsV3(jsonWriter);
            await streamWriter.FlushAsync();

            exportedFiles.Add(description.GroupName, filePath);
            Console.WriteLine($"✅ Exported {apiName} {description.GroupName}: {filePath}");
        }

        return exportedFiles;
    }
}

/// <summary>
/// Extension methods for exporting OpenAPI specs during application startup.
/// </summary>
public static class OpenApiExporterExtensions
{
    /// <summary>
    /// Exports OpenAPI specifications to files when in Development environment.
    /// Useful for generating specs during local development.
    /// </summary>
    /// <param name="app">The web application</param>
    /// <param name="outputDirectory">Directory to save specs (default: ./openapi-specs)</param>
    public static async Task ExportOpenApiSpecsAsync(this WebApplication app, string? outputDirectory = null)
    {
        outputDirectory ??= Path.Combine(Directory.GetCurrentDirectory(), "openapi-specs");

        var swaggerProvider = app.Services.GetRequiredService<ISwaggerProvider>();
        var apiVersionProvider = app.Services.GetRequiredService<IApiVersionDescriptionProvider>();

        var exporter = new OpenApiExporter(swaggerProvider, apiVersionProvider);
        var exportedFiles = await exporter.ExportAllVersionsAsync(outputDirectory);

        Console.WriteLine($"\n📄 Exported {exportedFiles.Count} OpenAPI specification(s) to: {outputDirectory}");
        Console.WriteLine("These files can be used for APIM import without requiring a running API.\n");
    }

    /// <summary>
    /// Exports OpenAPI specs only if a specific environment variable is set.
    /// Useful for CI/CD pipelines.
    /// </summary>
    /// <param name="app">The web application</param>
    /// <param name="environmentVariable">Environment variable name (default: EXPORT_OPENAPI_SPECS)</param>
    /// <param name="outputDirectory">Directory to save specs</param>
    public static async Task ExportOpenApiSpecsIfConfiguredAsync(
        this WebApplication app,
        string environmentVariable = "EXPORT_OPENAPI_SPECS",
        string? outputDirectory = null)
    {
        var shouldExport = Environment.GetEnvironmentVariable(environmentVariable);

        if (string.IsNullOrEmpty(shouldExport) || shouldExport.ToLower() != "true")
        {
            Console.WriteLine($"ℹ️ Skipping OpenAPI export (set {environmentVariable}=true to enable)");
            return;
        }

        outputDirectory ??= Environment.GetEnvironmentVariable("OPENAPI_OUTPUT_DIR")
            ?? Path.Combine(Directory.GetCurrentDirectory(), "openapi-specs");

        await app.ExportOpenApiSpecsAsync(outputDirectory);
    }
}

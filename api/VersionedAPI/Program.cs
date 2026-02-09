using Asp.Versioning;
using Asp.Versioning.ApiExplorer;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add API Versioning
builder.Services.AddApiVersioning(options =>
{
    // Specify the default API version
    options.DefaultApiVersion = new ApiVersion(1, 0);

    // Assume default version when not specified
    options.AssumeDefaultVersionWhenUnspecified = true;

    // Report API versions in response headers
    options.ReportApiVersions = true;

    // Use URL path versioning (e.g., /v1/products, /v2/products)
    // This is the RECOMMENDED approach for APIM!
    options.ApiVersionReader = new UrlSegmentApiVersionReader();

    /* Alternative versioning schemes (comment out UrlSegmentApiVersionReader above):

    // Query string versioning: /products?api-version=1.0
    options.ApiVersionReader = new QueryStringApiVersionReader("api-version");

    // Header versioning: Api-Version: 1.0
    options.ApiVersionReader = new HeaderApiVersionReader("Api-Version");

    // Multiple schemes (supports multiple methods):
    options.ApiVersionReader = ApiVersionReader.Combine(
        new UrlSegmentApiVersionReader(),
        new QueryStringApiVersionReader("api-version"),
        new HeaderApiVersionReader("Api-Version")
    );
    */
})
.AddMvc() // Required for controllers
.AddApiExplorer(options =>
{
    // Format the version as "'v'major[.minor][-status]"
    options.GroupNameFormat = "'v'VVV";

    // Substitute version in URL
    options.SubstituteApiVersionInUrl = true;
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Configure Swagger to generate SEPARATE documents per version
// This is KEY for APIM to understand multiple versions!
var apiVersionDescriptionProvider = builder.Services.BuildServiceProvider()
    .GetRequiredService<IApiVersionDescriptionProvider>();

builder.Services.AddSwaggerGen(options =>
{
    // Create a Swagger document for EACH API version
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(description.GroupName, new OpenApiInfo
        {
            Title = $"Versioned API {description.ApiVersion}",
            Version = description.ApiVersion.ToString(),
            Description = description.IsDeprecated
                ? $"This API version (v{description.ApiVersion}) has been deprecated."
                : "A sample API demonstrating proper versioning for APIM",
            Contact = new OpenApiContact
            {
                Name = "API Team",
                Email = "api@example.com"
            }
        });
    }

    // Include XML comments
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

var app = builder.Build();

// Enable Swagger for all environments (for demo purposes)
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    // Create a Swagger endpoint for EACH version
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerEndpoint(
            $"/swagger/{description.GroupName}/swagger.json",
            description.GroupName.ToUpperInvariant());
    }

    options.RoutePrefix = string.Empty; // Serve at root
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// ============================================================================
// OPTIONAL: Export OpenAPI Specs to Files
// ============================================================================
// This allows APIM to import from files instead of requiring a running API.
// Uncomment ONE of the options below based on your needs:

// OPTION 1: Export in Development environment only
// if (app.Environment.IsDevelopment())
// {
//     await app.ExportOpenApiSpecsAsync("./openapi-specs");
// }

// OPTION 2: Export when environment variable is set (recommended for CI/CD)
// Usage: EXPORT_OPENAPI_SPECS=true dotnet run
// await app.ExportOpenApiSpecsIfConfiguredAsync();

// OPTION 3: Export via command line argument
// Usage: dotnet run -- --export-openapi
if (args.Contains("--export-openapi"))
{
    var outputDir = args.Contains("--output")
        ? args[Array.IndexOf(args, "--output") + 1]
        : "./openapi-specs";

    await app.ExportOpenApiSpecsAsync(outputDir);

    Console.WriteLine("✅ OpenAPI export complete. Exiting...");
    Environment.Exit(0);
}

// ============================================================================

app.Run();

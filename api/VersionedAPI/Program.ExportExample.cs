// This file shows different ways to export OpenAPI specs from your API.
// Choose the approach that best fits your deployment pipeline.

using Asp.Versioning;
using Asp.Versioning.ApiExplorer;
using Microsoft.OpenApi.Models;

namespace VersionedAPI;

/// <summary>
/// Example configurations for exporting OpenAPI specifications.
/// Copy the relevant sections to your Program.cs based on your needs.
/// </summary>
public class ProgramExportExamples
{
    // ============================================================================
    // OPTION 1: Export During Development (Local Testing)
    // ============================================================================
    public static async Task Example1_ExportDuringDevelopment(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ... configure services (API versioning, Swagger, etc.)

        var app = builder.Build();

        // ... configure middleware (UseSwagger, etc.)

        // Export OpenAPI specs in Development environment
        if (app.Environment.IsDevelopment())
        {
            await app.ExportOpenApiSpecsAsync("./openapi-specs");
        }

        app.Run();
    }

    // ============================================================================
    // OPTION 2: Export Based on Environment Variable (CI/CD Friendly)
    // ============================================================================
    public static async Task Example2_ExportWithEnvironmentVariable(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ... configure services

        var app = builder.Build();

        // ... configure middleware

        // Export if EXPORT_OPENAPI_SPECS=true is set
        // Usage: EXPORT_OPENAPI_SPECS=true dotnet run
        await app.ExportOpenApiSpecsIfConfiguredAsync();

        app.Run();
    }

    // ============================================================================
    // OPTION 3: Export and Exit (Build-Time Generation)
    // ============================================================================
    public static async Task Example3_ExportAndExit(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ... configure services

        var app = builder.Build();

        // ... configure middleware

        // Check for --export-openapi command line argument
        if (args.Contains("--export-openapi"))
        {
            var outputDir = args.Contains("--output")
                ? args[Array.IndexOf(args, "--output") + 1]
                : "./openapi-specs";

            await app.ExportOpenApiSpecsAsync(outputDir);

            Console.WriteLine("✅ Export complete. Exiting...");
            Environment.Exit(0);
        }

        app.Run();
    }

    // ============================================================================
    // OPTION 4: Custom Export with API Name
    // ============================================================================
    public static async Task Example4_CustomExport(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ... configure services

        var app = builder.Build();

        // ... configure middleware

        if (args.Contains("--export-openapi"))
        {
            var swaggerProvider = app.Services.GetRequiredService<ISwaggerProvider>();
            var apiVersionProvider = app.Services.GetRequiredService<IApiVersionDescriptionProvider>();

            var exporter = new OpenApiExporter(swaggerProvider, apiVersionProvider);

            // Export with custom naming: products-api-v1.json, products-api-v2.json
            var files = await exporter.ExportWithCustomNamingAsync(
                "./openapi-specs",
                "products-api"
            );

            foreach (var (version, filePath) in files)
            {
                Console.WriteLine($"✅ {version}: {filePath}");
            }

            Environment.Exit(0);
        }

        app.Run();
    }

    // ============================================================================
    // OPTION 5: Export to Multiple Locations (Dev/Staging/Prod)
    // ============================================================================
    public static async Task Example5_ExportToMultipleEnvironments(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ... configure services

        var app = builder.Build();

        // ... configure middleware

        if (args.Contains("--export-openapi"))
        {
            var swaggerProvider = app.Services.GetRequiredService<ISwaggerProvider>();
            var apiVersionProvider = app.Services.GetRequiredService<IApiVersionDescriptionProvider>();
            var exporter = new OpenApiExporter(swaggerProvider, apiVersionProvider);

            // Export to multiple environment directories
            var environments = new[] { "dev", "staging", "prod" };

            foreach (var env in environments)
            {
                var outputDir = Path.Combine("./openapi-specs", env);
                Console.WriteLine($"\n📁 Exporting to {env} environment...");

                await exporter.ExportAllVersionsAsync(outputDir);
            }

            Console.WriteLine("\n✅ All environments exported successfully!");
            Environment.Exit(0);
        }

        app.Run();
    }
}

/* ============================================================================
   USAGE EXAMPLES IN CI/CD PIPELINES
   ============================================================================

   1. During Build (Azure DevOps):
   ─────────────────────────────────────
   - script: |
       cd api/VersionedAPI
       EXPORT_OPENAPI_SPECS=true dotnet run
     displayName: 'Export OpenAPI Specs'

   2. As Separate Build Step:
   ─────────────────────────────────────
   - script: |
       cd api/VersionedAPI
       dotnet run -- --export-openapi --output $(Build.ArtifactStagingDirectory)/openapi-specs
     displayName: 'Generate OpenAPI Specifications'

   3. GitHub Actions:
   ─────────────────────────────────────
   - name: Export OpenAPI Specs
     run: |
       cd api/VersionedAPI
       dotnet run -- --export-openapi --output ./artifacts/openapi-specs
     env:
       EXPORT_OPENAPI_SPECS: true

   4. Docker Build:
   ─────────────────────────────────────
   # In Dockerfile
   RUN dotnet build
   RUN dotnet run -- --export-openapi --output /app/openapi-specs

   # Copy specs out during container build
   COPY /app/openapi-specs /output/

   5. Post-Build PowerShell:
   ─────────────────────────────────────
   $env:EXPORT_OPENAPI_SPECS="true"
   $env:OPENAPI_OUTPUT_DIR="./artifacts/openapi-specs"
   dotnet run --project api/VersionedAPI

   ============================================================================ */

/* ============================================================================
   INTEGRATION WITH AZURE STORAGE
   ============================================================================

   After exporting, upload to Azure Blob Storage:

   # Azure CLI
   az storage blob upload-batch \
     --account-name apimspecs123 \
     --destination openapi-specs \
     --source ./openapi-specs \
     --auth-mode login

   # PowerShell
   $storageAccount = Get-AzStorageAccount -ResourceGroupName "rg-apim" -Name "apimspecs123"
   Get-ChildItem ./openapi-specs/*.json | ForEach-Object {
       Set-AzStorageBlobContent `
         -File $_.FullName `
         -Container "openapi-specs" `
         -Blob $_.Name `
         -Context $storageAccount.Context
   }

   ============================================================================ */

/* ============================================================================
   RECOMMENDED WORKFLOW
   ============================================================================

   BUILD PIPELINE:
   1. dotnet build
   2. dotnet test
   3. dotnet run -- --export-openapi --output ./artifacts/openapi-specs
   4. Upload to Azure Blob Storage
   5. Publish build artifacts

   INFRASTRUCTURE PIPELINE:
   1. Download OpenAPI specs from blob storage (or build artifacts)
   2. Deploy APIM infrastructure (Bicep)
   3. Import APIs using specs from storage
   4. Configure policies
   5. Run integration tests

   This approach completely decouples API deployment from infrastructure deployment.

   ============================================================================ */

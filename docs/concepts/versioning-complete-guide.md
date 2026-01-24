# Complete API Versioning Guide for APIM

## The Problem You're Experiencing

```
❌ Your current situation:
C# API with Asp.Versioning → Generates Swagger with dropdown → Import to APIM → Only v1 shows!

✅ What you need:
C# API with Asp.Versioning → Separate OpenAPI per version → Import with Version Sets → All versions visible!
```

## Why This Happens

**The Issue:** When you import a single OpenAPI spec with multiple versions into APIM without a Version Set, APIM treats it as a single API and only shows one version.

**The Solution:** Create a **Version Set** in APIM and import each version as a separate API linked to that version set.

## Complete Solution: Step-by-Step

### Step 1: Configure C# API Correctly

The sample C# API in `/api/VersionedAPI` demonstrates the correct approach:

**Key Configuration in `Program.cs`:**

```csharp
// 1. Use URL Segment versioning (REQUIRED for APIM path-based versioning)
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
    // NOT QueryStringApiVersionReader - harder to work with in APIM
    // NOT HeaderApiVersionReader - invisible in Swagger UI
})
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";  // Formats as v1, v2, etc.
    options.SubstituteApiVersionInUrl = true;  // Replaces {version:apiVersion} in route
});

// 2. Generate SEPARATE Swagger documents per version
builder.Services.AddSwaggerGen(options =>
{
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        // This creates /swagger/v1/swagger.json and /swagger/v2/swagger.json
        options.SwaggerDoc(description.GroupName, new OpenApiInfo
        {
            Title = $"API {description.ApiVersion}",
            Version = description.ApiVersion.ToString()
        });
    }
});

// 3. Expose separate Swagger endpoints
app.UseSwaggerUI(options =>
{
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerEndpoint(
            $"/swagger/{description.GroupName}/swagger.json",
            description.GroupName.ToUpperInvariant()
        );
    }
});
```

**Controller Configuration:**

```csharp
// V1 Controller
[ApiController]
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]  // Important: v{version:apiVersion}
public class ProductsControllerV1 : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public ActionResult<IEnumerable<ProductV1>> GetAll() { }
}

// V2 Controller
[ApiController]
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/products")]  // Same route template
public class ProductsControllerV2 : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("2.0")]
    public ActionResult<IEnumerable<ProductV2>> GetAll() { }
}
```

### Step 2: Generate Separate OpenAPI Specs

When you run the API, you'll get separate endpoints:

```
https://localhost:7001/swagger/v1/swagger.json  ← Version 1 spec
https://localhost:7001/swagger/v2/swagger.json  ← Version 2 spec
```

**Download both specs:**

```bash
# Download v1 spec
curl https://your-api.azurewebsites.net/swagger/v1/swagger.json -o products-v1.json

# Download v2 spec
curl https://your-api.azurewebsites.net/swagger/v2/swagger.json -o products-v2.json
```

### Step 3: Create Version Set in APIM (Bicep)

```bicep
// Create the version set FIRST
module versionSet './modules/api-version-set.bicep' = {
  name: 'products-version-set'
  params: {
    apimServiceName: apimName
    versionSetName: 'products-versions'
    versionSetDisplayName: 'Products API'
    versioningScheme: 'Segment'  // URL path: /v1/..., /v2/...
  }
}
```

### Step 4: Import Each Version Separately (Bicep)

```bicep
// Import v1
module apiV1 './modules/api-versioned.bicep' = {
  name: 'products-v1'
  params: {
    apimServiceName: apimName
    apiName: 'products-api-v1'
    apiDisplayName: 'Products API v1'
    apiVersion: 'v1'
    apiPath: 'products'
    serviceUrl: 'https://your-backend.azurewebsites.net/v1'
    versionSetId: versionSet.outputs.versionSetId  // Link to version set!
    openApiSpec: loadTextContent('../specs/products-v1.json')
  }
}

// Import v2
module apiV2 './modules/api-versioned.bicep' = {
  name: 'products-v2'
  params: {
    apimServiceName: apimName
    apiName: 'products-api-v2'
    apiDisplayName: 'Products API v2'
    apiVersion: 'v2'
    apiPath: 'products'  // Same path!
    serviceUrl: 'https://your-backend.azurewebsites.net/v2'
    versionSetId: versionSet.outputs.versionSetId  // Same version set!
    isCurrent: true  // Mark v2 as current
    openApiSpec: loadTextContent('../specs/products-v2.json')
  }
}
```

### Step 5: Result in APIM

After deployment, you'll see in Azure Portal:

```
APIs
└── Products API (Version Set)
    ├── Products API v1  (/v1/products)
    └── Products API v2  (/v2/products) [Current]
```

**Both versions are visible and accessible:**

```http
# Access v1
GET https://your-apim.azure-api.net/v1/products
Ocp-Apim-Subscription-Key: your-key

# Access v2
GET https://your-apim.azure-api.net/v2/products
Ocp-Apim-Subscription-Key: your-key
```

## Common Mistakes & Solutions

### ❌ Mistake 1: Importing Combined Swagger

**What teams do wrong:**
```bash
# Import single swagger.json with all versions
# APIM sees this as ONE API, shows only v1
curl https://api.example.com/swagger/swagger.json -o api.json
# Import to APIM → Only v1 visible!
```

**✅ Correct approach:**
```bash
# Download SEPARATE specs for each version
curl https://api.example.com/swagger/v1/swagger.json -o api-v1.json
curl https://api.example.com/swagger/v2/swagger.json -o api-v2.json
# Import each to APIM with version set
```

### ❌ Mistake 2: No Version Set

**What teams do wrong:**
```bicep
// Import v1 without version set
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    displayName: 'Products API v1'
    path: 'v1/products'
    // Missing: apiVersionSetId
  }
}
// Result: APIs are unrelated, no grouping
```

**✅ Correct approach:**
```bicep
// Create version set first
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  name: 'products-versions'
  properties: {
    displayName: 'Products API'
    versioningScheme: 'Segment'
  }
}

// Import v1 WITH version set
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    displayName: 'Products API v1'
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id  // ← THIS IS KEY!
    path: 'products'  // Not 'v1/products' - version set handles that!
  }
}
```

### ❌ Mistake 3: Wrong Path Configuration

**What teams do wrong:**
```bicep
// V1
path: 'v1/products'  // ❌ Hardcoded version

// V2
path: 'v2/products'  // ❌ Hardcoded version

// Result: URLs are /v1/products and /v2/products but NOT grouped
```

**✅ Correct approach:**
```bicep
// V1
apiVersion: 'v1'       // ✅ Version specified here
path: 'products'       // ✅ Base path only
apiVersionSetId: versionSet.id

// V2
apiVersion: 'v2'       // ✅ Version specified here
path: 'products'       // ✅ Same base path
apiVersionSetId: versionSet.id  // ✅ Same version set

// Result: URLs are /v1/products and /v2/products AND grouped!
```

### ❌ Mistake 4: Using Query String or Header Versioning in C#

**What teams do wrong:**
```csharp
// Using query string versioning
options.ApiVersionReader = new QueryStringApiVersionReader();
// Result: URLs are /products?api-version=1
// Hard to work with in APIM Swagger UI
```

**✅ Correct approach:**
```csharp
// Use URL segment versioning
options.ApiVersionReader = new UrlSegmentApiVersionReader();
// Result: URLs are /v1/products, /v2/products
// Works perfectly with APIM!
```

## Azure Portal Method (Manual)

If you prefer using Azure Portal instead of Bicep:

### 1. Create Version Set

1. Go to APIM → **APIs**
2. Click **+ Add version set**
3. Configure:
   - **Name:** `products-versions`
   - **Display name:** `Products API`
   - **Versioning scheme:** `Path` (URL path segment)
4. Click **Save**

### 2. Import V1

1. Click **+ Add API**
2. Select **OpenAPI**
3. Upload `products-v1.json`
4. Configure:
   - **Versioning:** Select `Add to existing version set`
   - **Version set:** Select `products-versions`
   - **Version identifier:** `v1`
   - **Display name:** `Products API v1`
   - **URL suffix:** `products` (NOT `v1/products`)
5. Click **Create**

### 3. Import V2

1. Click **+ Add API**
2. Select **OpenAPI**
3. Upload `products-v2.json`
4. Configure:
   - **Versioning:** Select `Add to existing version set`
   - **Version set:** Select `products-versions`
   - **Version identifier:** `v2`
   - **Display name:** `Products API v2`
   - **URL suffix:** `products` (same as v1!)
   - **Set as current:** ✅ Yes
5. Click **Create**

## Testing

### Test V1

```http
### Version 1 - Basic products
GET https://your-apim.azure-api.net/v1/products
Ocp-Apim-Subscription-Key: {{key}}

### Get product by ID (v1 response - basic fields only)
GET https://your-apim.azure-api.net/v1/products/1
Ocp-Apim-Subscription-Key: {{key}}
```

**V1 Response:**
```json
{
  "id": 1,
  "name": "Laptop",
  "price": 999.99
}
```

### Test V2

```http
### Version 2 - Enhanced products with filtering
GET https://your-apim.azure-api.net/v2/products?category=Electronics
Ocp-Apim-Subscription-Key: {{key}}

### Get product by ID (v2 response - full details)
GET https://your-apim.azure-api.net/v2/products/1
Ocp-Apim-Subscription-Key: {{key}}

### Search (NEW in v2)
GET https://your-apim.azure-api.net/v2/products/search?query=laptop
Ocp-Apim-Subscription-Key: {{key}}
```

**V2 Response:**
```json
{
  "id": 1,
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 999.99,
  "category": "Electronics",
  "stock": 50,
  "imageUrl": "https://example.com/laptop.jpg"
}
```

## Versioning Strategies

### Strategy 1: Same Backend, Different Versions

Backend handles version routing:

```bicep
// Both versions point to same backend
serviceUrl: 'https://backend.azurewebsites.net'
// Backend sees: /v1/products or /v2/products
```

### Strategy 2: Different Backends per Version

Separate deployments:

```bicep
// V1 → Old backend
serviceUrl: 'https://backend-v1.azurewebsites.net/v1'

// V2 → New backend
serviceUrl: 'https://backend-v2.azurewebsites.net/v2'
```

### Strategy 3: Version-Specific Policies

Apply different policies to different versions:

```xml
<!-- V1 Policy - Limited features -->
<policies>
    <inbound>
        <base />
        <rate-limit calls="10" renewal-period="60" />
    </inbound>
</policies>

<!-- V2 Policy - Enhanced features -->
<policies>
    <inbound>
        <base />
        <rate-limit calls="100" renewal-period="60" />
        <cache-lookup vary-by-developer="false" />
    </inbound>
    <outbound>
        <base />
        <cache-store duration="3600" />
    </outbound>
</policies>
```

## Deprecating Old Versions

### Mark as Deprecated

```bicep
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    // ... other properties
    apiVersion: 'v1'
    apiVersionDescription: 'DEPRECATED: Please migrate to v2 by 2024-12-31'
  }
}
```

### Add Deprecation Policy

```xml
<policies>
    <inbound>
        <base />
        <!-- Add deprecation warning header -->
        <set-header name="X-API-Deprecated" exists-action="override">
            <value>true</value>
        </set-header>
        <set-header name="X-API-Sunset" exists-action="override">
            <value>2024-12-31</value>
        </set-header>
        <set-header name="Link" exists-action="override">
            <value>&lt;https://your-apim.azure-api.net/v2/products&gt;; rel="successor-version"</value>
        </set-header>
    </inbound>
</policies>
```

## Quick Reference

| Concept | What It Is | Example |
|---------|-----------|---------|
| **Version Set** | Logical grouping | "Products API" contains v1, v2, v3 |
| **API Version** | Specific version | v1, v2, 2.0, 2024-01-01 |
| **Version Scheme** | How version is specified | Path (/v1), Query (?v=1), Header (Api-Version: 1) |
| **Version Identifier** | The version number | v1, v2, 1.0, 2.0 |
| **isCurrent** | Recommended version | v2 is current, v1 is legacy |

## Summary

**Your Problem:** Only seeing v1 because version sets weren't configured

**The Solution:**
1. ✅ Configure C# API with URL segment versioning
2. ✅ Generate separate OpenAPI specs per version
3. ✅ Create APIM Version Set
4. ✅ Import each version as separate API linked to version set
5. ✅ Both versions now visible and accessible!

**Files to Reference:**
- `/api/VersionedAPI/` - Complete C# example
- `/bicep/modules/api-version-set.bicep` - Version set module
- `/bicep/modules/api-versioned.bicep` - Versioned API module
- `/bicep/examples/versioned-api-deployment.bicep` - Complete example

Now your team can see ALL versions in APIM! 🎉

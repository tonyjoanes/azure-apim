# API Versioning Troubleshooting Guide

## Common Problems & Solutions

### Problem 1: "I can only see v1 in APIM, but my API has v2!"

**Symptoms:**
- C# API has multiple versions
- Swagger dropdown shows v1 and v2
- After importing to APIM, only v1 is visible
- APIM shows only one API, not multiple versions

**Root Cause:**
You imported a combined OpenAPI spec without creating a Version Set.

**Solution:**

1. **Download separate specs per version:**
```bash
curl https://your-api.azurewebsites.net/swagger/v1/swagger.json -o v1.json
curl https://your-api.azurewebsites.net/swagger/v2/swagger.json -o v2.json
```

2. **Create a Version Set in APIM:**
```bicep
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  name: 'my-api-versions'
  properties: {
    displayName: 'My API'
    versioningScheme: 'Segment'
  }
}
```

3. **Import each version separately:**
```bicep
// Import v1
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id  // ← Key!
    path: 'myapi'
  }
}

// Import v2
resource apiV2 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v2'
    apiVersionSetId: versionSet.id  // ← Same version set!
    path: 'myapi'
  }
}
```

---

### Problem 2: "My C# API uses query string versioning, but APIM shows weird URLs"

**Symptoms:**
- C# API configured with `QueryStringApiVersionReader`
- URLs are `/products?api-version=1.0`
- Swagger UI works fine
- APIM import creates confusing paths

**Root Cause:**
Query string versioning doesn't work well with APIM's UI and OpenAPI import.

**Solution:**

**Switch to URL segment versioning in C#:**

```csharp
// Before (problematic)
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new QueryStringApiVersionReader("api-version");
    // URLs: /products?api-version=1.0
});

// After (recommended)
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
    // URLs: /v1/products
});
```

**Update controller routes:**
```csharp
// Before
[Route("products")]

// After
[Route("v{version:apiVersion}/products")]
```

**Benefits:**
- ✅ Clear, visible versioning
- ✅ Works perfectly with APIM
- ✅ Better for caching
- ✅ More discoverable

---

### Problem 3: "Version Set exists, but APIs aren't grouped"

**Symptoms:**
- Created Version Set in APIM
- Imported multiple API versions
- APIs show as separate, unrelated APIs
- No version grouping visible

**Root Cause:**
APIs weren't linked to the Version Set during import.

**Solution:**

**Check if `apiVersionSetId` is set:**

```bicep
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    displayName: 'My API v1'
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id  // ← Must have this!
    path: 'myapi'
  }
}
```

**Via Azure Portal:**
1. Go to API → Settings
2. Scroll to "Versioning"
3. Select "Add to existing version set"
4. Choose your version set
5. Enter version identifier (e.g., v1)
6. Save

---

### Problem 4: "URLs are wrong - showing /v1/v1/products"

**Symptoms:**
- Expected: `/v1/products`
- Actual: `/v1/v1/products`
- Double version prefix in URL

**Root Cause:**
Both the Version Set AND the API path include the version.

**Solution:**

**Fix the API path - don't include version:**

```bicep
// Wrong
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v1'
    path: 'v1/products'  // ❌ Don't hardcode version in path!
    apiVersionSetId: versionSet.id
  }
}

// Correct
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v1'  // ← Version specified here
    path: 'products'  // ✅ Base path only!
    apiVersionSetId: versionSet.id
  }
}
```

**Result:**
- Version Set adds: `/v1`
- Path adds: `/products`
- Final URL: `/v1/products` ✅

---

### Problem 5: "404 errors when calling versioned endpoints"

**Symptoms:**
- API imported successfully
- Swagger shows endpoints
- Calling `/v1/products` returns 404
- Backend is working fine

**Root Cause:**
Backend URL configuration doesn't match the request path.

**Solution:**

**Check backend URL configuration:**

```bicep
// If backend expects /v1/products
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v1'
    path: 'products'
    serviceUrl: 'https://backend.azurewebsites.net'  // ✅ No /v1 here
    // APIM sends: /v1/products → Backend receives: /v1/products
  }
}

// If backend doesn't expect version prefix
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v1'
    path: 'products'
    serviceUrl: 'https://backend.azurewebsites.net/v1'  // ✅ Version in backend URL
    // APIM sends: /v1/products → Backend receives: /v1/v1/products
    // OR use rewrite policy to remove /v1 prefix
  }
}
```

**Alternative: Use rewrite policy:**

```xml
<policies>
    <inbound>
        <base />
        <!-- Remove /v1 prefix before sending to backend -->
        <rewrite-uri template="/products" copy-unmatched-params="true" />
    </inbound>
</policies>
```

---

### Problem 6: "Can't generate separate Swagger docs in C#"

**Symptoms:**
- Only one Swagger doc generated
- All versions in one document
- Dropdown shows versions, but single JSON file

**Root Cause:**
Swagger not configured to generate multiple documents.

**Solution:**

**Configure Swagger properly:**

```csharp
var builder = WebApplication.CreateBuilder(args);

// Get the API version provider
var apiVersionDescriptionProvider = builder.Services.BuildServiceProvider()
    .GetRequiredService<IApiVersionDescriptionProvider>();

builder.Services.AddSwaggerGen(options =>
{
    // Create a document for EACH version
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(description.GroupName, new OpenApiInfo
        {
            Title = $"My API {description.ApiVersion}",
            Version = description.ApiVersion.ToString()
        });
    }
});

var app = builder.Build();

app.UseSwaggerUI(options =>
{
    // Add endpoint for EACH version
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerEndpoint(
            $"/swagger/{description.GroupName}/swagger.json",
            description.GroupName.ToUpperInvariant()
        );
    }
});
```

**Verify it works:**
```bash
# Should return v1 spec only
curl https://localhost:7001/swagger/v1/swagger.json

# Should return v2 spec only
curl https://localhost:7001/swagger/v2/swagger.json
```

---

### Problem 7: "Version not showing in route"

**Symptoms:**
- Route defined as `[Route("v{version:apiVersion}/products")]`
- Actual URL is `/v{version:apiVersion}/products`
- Version placeholder not replaced

**Root Cause:**
Missing `SubstituteApiVersionInUrl` configuration.

**Solution:**

```csharp
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
})
.AddApiExplorer(options =>
{
    options.SubstituteApiVersionInUrl = true;  // ← Add this!
});
```

---

### Problem 8: "Different teams using different versioning methods"

**Symptoms:**
- Team A uses URL path: `/v1/products`
- Team B uses query string: `/products?api-version=1`
- Team C uses headers: `Api-Version: 1`
- Difficult to manage in APIM

**Root Cause:**
No standardization across teams.

**Solution:**

**Standardize on URL segment versioning:**

```csharp
// Standard for all teams
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
});

// Controller template
[Route("v{version:apiVersion}/[controller]")]
```

**Why URL segments?**
- ✅ Most visible
- ✅ Best APIM support
- ✅ Easy to cache
- ✅ Clear in logs
- ✅ Works in all tools

**Create team guidelines document:**

```markdown
## API Versioning Standard

All APIs MUST use URL segment versioning:
- Format: /v{major}/resource
- Example: /v1/products, /v2/products
- Not allowed: Query string or header versioning
- Reason: Consistent APIM integration
```

---

### Problem 9: "How do I deprecate v1?"

**Symptoms:**
- Want to phase out v1
- Need to notify users
- Don't want to break existing users

**Solution:**

**1. Mark version as deprecated in C#:**

```csharp
[ApiVersion("1.0", Deprecated = true)]
[Route("v{version:apiVersion}/products")]
public class ProductsControllerV1 : ControllerBase
{
    // ...
}
```

**2. Add deprecation info to OpenAPI:**

```csharp
options.SwaggerDoc("v1", new OpenApiInfo
{
    Title = "My API v1",
    Version = "v1",
    Description = "⚠️ DEPRECATED: This version will be removed on 2024-12-31. Please migrate to v2."
});
```

**3. Add deprecation headers in APIM:**

```xml
<policies>
    <inbound>
        <base />
    </inbound>
    <outbound>
        <base />
        <!-- Add deprecation headers -->
        <set-header name="X-API-Deprecated" exists-action="override">
            <value>true</value>
        </set-header>
        <set-header name="X-API-Sunset" exists-action="override">
            <value>2024-12-31T23:59:59Z</value>
        </set-header>
        <set-header name="Link" exists-action="override">
            <value>&lt;https://your-apim.azure-api.net/v2/products&gt;; rel="successor-version"</value>
        </set-header>
        <set-header name="Deprecation" exists-action="override">
            <value>@{
                return DateTime.Parse("2024-12-31").ToString("R");
            }</value>
        </set-header>
    </outbound>
</policies>
```

**4. Monitor v1 usage:**

```kusto
// Application Insights query
requests
| where url contains "/v1/"
| summarize RequestCount = count() by bin(timestamp, 1d)
| render timechart
```

**5. Communication plan:**
- Email users 3 months before sunset
- Add banner to developer portal
- Include in API response headers
- Update documentation

---

### Problem 10: "Backend returns different response for same version"

**Symptoms:**
- Same version (v1) returns different responses
- Inconsistent behavior
- Sometimes has new fields, sometimes doesn't

**Root Cause:**
Backend was updated without creating a new version.

**Solution:**

**Create version discipline:**

```yaml
# versioning-policy.md

## When to Create a New Version

Create new version (v2, v3, etc.) when:
- ✅ Adding required fields
- ✅ Changing field types
- ✅ Removing fields
- ✅ Changing behavior
- ✅ Breaking changes

DO NOT create new version for:
- ❌ Bug fixes
- ❌ Adding optional fields (use revisions)
- ❌ Performance improvements
- ❌ Internal refactoring

## Version Lifecycle

v1 → v2 (breaking changes)
v2.0 → v2.1 (revision, non-breaking)
```

**Use API revisions for non-breaking changes:**

```bicep
resource apiV2Revision 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    apiVersion: 'v2'
    apiRevision: '2'  // v2.2 (non-breaking update)
    apiRevisionDescription: 'Added optional imageUrl field'
  }
}
```

---

## Quick Diagnosis Checklist

Run through this checklist to diagnose versioning issues:

### ✅ C# API Configuration

- [ ] Using `UrlSegmentApiVersionReader`
- [ ] Route has `v{version:apiVersion}` pattern
- [ ] `SubstituteApiVersionInUrl = true`
- [ ] Separate Swagger doc per version
- [ ] `GroupNameFormat = "'v'VVV"`
- [ ] Controllers decorated with `[ApiVersion("1.0")]`
- [ ] Operations have `[MapToApiVersion("1.0")]`

### ✅ OpenAPI Specs

- [ ] Can access `/swagger/v1/swagger.json`
- [ ] Can access `/swagger/v2/swagger.json`
- [ ] Each spec has different version in `info.version`
- [ ] Paths include version: `/v1/products`
- [ ] Downloaded both specs separately

### ✅ APIM Configuration

- [ ] Version Set created
- [ ] Version Set has correct scheme (Segment/Query/Header)
- [ ] V1 API has `apiVersionSetId`
- [ ] V2 API has same `apiVersionSetId`
- [ ] V1 API has `apiVersion: 'v1'`
- [ ] V2 API has `apiVersion: 'v2'`
- [ ] Both APIs have same `path` (without version prefix)
- [ ] `isCurrent` set appropriately

### ✅ Testing

- [ ] Can call `/v1/products` through APIM
- [ ] Can call `/v2/products` through APIM
- [ ] Both versions visible in Azure Portal
- [ ] Version dropdown appears in Developer Portal
- [ ] Responses differ between versions
- [ ] No 404 errors
- [ ] No double version prefix (`/v1/v1/`)

---

## Getting Help

Still stuck? Check:

1. **Example Code**: `/api/VersionedAPI/` - Complete working example
2. **Bicep Templates**: `/bicep/modules/api-version-set.bicep`
3. **Complete Guide**: `/docs/concepts/versioning-complete-guide.md`
4. **Test Files**: `/tests/versioned-api.http`

If issue persists:
1. Compare your setup to `/api/VersionedAPI/`
2. Check APIM logs in Azure Portal
3. Enable tracing: `Ocp-Apim-Trace: true`
4. Review Application Insights logs

---

## Summary of Common Fixes

| Problem | Quick Fix |
|---------|-----------|
| Only v1 visible | Create Version Set, link APIs to it |
| Query string versioning | Switch to URL segment versioning |
| APIs not grouped | Set `apiVersionSetId` on APIs |
| Double version (`/v1/v1/`) | Remove version from `path`, only in `apiVersion` |
| 404 errors | Check backend URL and rewrite policies |
| Single Swagger doc | Configure separate docs per version |
| Version not in URL | Set `SubstituteApiVersionInUrl = true` |
| Different versioning methods | Standardize on URL segments |
| Need to deprecate | Add deprecation headers and sunset date |
| Inconsistent responses | Use proper versioning discipline |

Remember: **Version Sets are the key to making versioning work in APIM!** 🔑

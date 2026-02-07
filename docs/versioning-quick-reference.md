# API Versioning Quick Reference Card

**For Developers:** Keep this handy when implementing versioned APIs

---

## ✅ The Checklist

When creating or updating a versioned API:

- [ ] Using URL path versioning (`/v1/resource`, not query/header)
- [ ] Asp.Versioning packages installed (v8.0+)
- [ ] `UrlSegmentApiVersionReader` configured
- [ ] `SubstituteApiVersionInUrl = true` set
- [ ] Separate Swagger doc per version
- [ ] Controller route: `[Route("v{version:apiVersion}/[controller]")]`
- [ ] Version attribute: `[ApiVersion("X.0")]`
- [ ] Operation mapping: `[MapToApiVersion("X.0")]`
- [ ] APIM Version Set created or exists
- [ ] API linked to Version Set (`apiVersionSetId`)
- [ ] Tests written for new version
- [ ] Migration guide created (if breaking changes)
- [ ] Documentation updated

---

## 🚀 Quick Start Template

### 1. Install Packages

```bash
dotnet add package Asp.Versioning.Http --version 8.0.0
dotnet add package Asp.Versioning.Mvc.ApiExplorer --version 8.0.0
```

### 2. Configure in Program.cs

```csharp
using Asp.Versioning;
using Asp.Versioning.ApiExplorer;

var builder = WebApplication.CreateBuilder(args);

// Add API Versioning
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
})
.AddMvc()
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});

// Rest of your configuration...
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Swagger with separate docs per version
var provider = builder.Services.BuildServiceProvider()
    .GetRequiredService<IApiVersionDescriptionProvider>();

builder.Services.AddSwaggerGen(options =>
{
    foreach (var description in provider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(description.GroupName, new()
        {
            Title = $"My API {description.ApiVersion}",
            Version = description.ApiVersion.ToString()
        });
    }
});

var app = builder.Build();

// Swagger UI with all versions
app.UseSwaggerUI(options =>
{
    foreach (var description in provider.ApiVersionDescriptions)
    {
        options.SwaggerEndpoint(
            $"/swagger/{description.GroupName}/swagger.json",
            description.GroupName.ToUpperInvariant()
        );
    }
});

app.MapControllers();
app.Run();
```

### 3. Create Versioned Controllers

**V1 Controller:**
```csharp
using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;

namespace MyAPI.Controllers.V1;

[ApiController]
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public ActionResult<IEnumerable<ProductV1>> GetAll()
    {
        // V1 implementation
        return Ok(products);
    }
}
```

**V2 Controller:**
```csharp
using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;

namespace MyAPI.Controllers.V2;

[ApiController]
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("2.0")]
    public ActionResult<IEnumerable<ProductV2>> GetAll()
    {
        // V2 implementation with enhancements
        return Ok(products);
    }
}
```

---

## 🏗️ APIM Version Set (Bicep)

### Create Version Set

```bicep
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apimService
  name: 'my-api-versions'
  properties: {
    displayName: 'My API'
    description: 'My API with multiple versions'
    versioningScheme: 'Segment'
  }
}
```

### Link API to Version Set

```bicep
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: 'my-api-v1'
  properties: {
    displayName: 'My API v1'
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id  // 🔑 THIS IS KEY!
    path: 'myapi'                   // NO version prefix here
    serviceUrl: 'https://backend.azurewebsites.net/v1'
    subscriptionRequired: true
    protocols: ['https']
  }
}
```

---

## 🎯 When to Create New Version

### ✅ Create New Version (Breaking Changes)

| Change | Example |
|--------|---------|
| Remove field | Delete `phoneNumber` from User |
| Rename field | `userId` → `id` |
| Change type | `age: string` → `age: number` |
| Make required | `email` becomes required |
| Change structure | `{ data: [] }` → `{ items: [] }` |
| Remove endpoint | Delete `DELETE /users/{id}` |

### ❌ Use Revision (Non-Breaking Changes)

| Change | Example |
|--------|---------|
| Add optional field | Add optional `middleName` |
| Add endpoint | Add `GET /users/{id}/settings` |
| Bug fix | Fix date format |
| Performance | Optimize query |
| Documentation | Update descriptions |

---

## 📝 Common Patterns

### Multiple Versions in Same File

```csharp
[ApiController]
[ApiVersion("1.0")]
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public ActionResult<ProductV1> GetV1() { }

    [HttpGet]
    [MapToApiVersion("2.0")]
    public ActionResult<ProductV2> GetV2() { }
}
```

### Deprecating a Version

```csharp
[ApiController]
[ApiVersion("1.0", Deprecated = true)]
[Route("v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    // V1 implementation
}
```

### Version-Specific Routes

```csharp
// V2 has new endpoint that V1 doesn't
[HttpGet("search")]
[MapToApiVersion("2.0")]
public ActionResult<IEnumerable<ProductV2>> Search(string query)
{
    // Only available in v2
}
```

---

## 🧪 Testing

### .http File Template

```http
### Variables
@baseUrl = https://your-apim.azure-api.net
@key = your-subscription-key

### Test V1
GET {{baseUrl}}/v1/products
Ocp-Apim-Subscription-Key: {{key}}

### Test V2
GET {{baseUrl}}/v2/products
Ocp-Apim-Subscription-Key: {{key}}

### Test V2-only feature
GET {{baseUrl}}/v2/products/search?query=test
Ocp-Apim-Subscription-Key: {{key}}

### Should 404 on V1 (doesn't exist)
GET {{baseUrl}}/v1/products/search?query=test
Ocp-Apim-Subscription-Key: {{key}}
```

---

## 🐛 Troubleshooting

### Problem: Only v1 visible in APIM

**Solution:** Check Version Set configuration

```bash
# Verify Version Set exists
az apim api versionset list --service-name your-apim --resource-group your-rg

# Check if API is linked to version set
az apim api show --api-id your-api-v1 --service-name your-apim --resource-group your-rg --query apiVersionSetId
```

### Problem: 404 on versioned routes

**Solution:** Check `SubstituteApiVersionInUrl`

```csharp
// Must have this:
.AddApiExplorer(options =>
{
    options.SubstituteApiVersionInUrl = true;  // ← Required!
});
```

### Problem: Double version in URL (/v1/v1/products)

**Solution:** Remove version from APIM path

```bicep
// Wrong
path: 'v1/products'  // ❌

// Correct
path: 'products'     // ✅
apiVersion: 'v1'     // Version specified here
```

### Problem: Can't generate separate Swagger docs

**Solution:** Configure SwaggerGen per version

```csharp
builder.Services.AddSwaggerGen(options =>
{
    // Must create doc for EACH version
    foreach (var desc in provider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(desc.GroupName, new OpenApiInfo
        {
            Title = $"API {desc.ApiVersion}",
            Version = desc.ApiVersion.ToString()
        });
    }
});
```

---

## 📚 Resources

**Documentation:**
- Complete Guide: `/docs/concepts/versioning-complete-guide.md`
- Troubleshooting: `/docs/concepts/versioning-troubleshooting.md`
- Full Guidelines: `/docs/api-versioning-guidelines.md`

**Examples:**
- Working API: `/api/VersionedAPI/`
- Bicep Templates: `/bicep/modules/api-version-set.bicep`
- Test Suite: `/tests/versioned-api.http`

**Getting Help:**
- Office Hours: Fridays 2-3 PM
- Slack: #api-versioning-help
- Email: architecture-team@company.com

---

## 💡 Pro Tips

1. **Start with v1** even if you think you'll never version
   - Adding versioning later is a breaking change itself

2. **Keep models separate** per version
   - ProductV1, ProductV2, etc.
   - Don't try to share models between versions

3. **Test both versions** in your test suite
   - Don't assume v2 works because v1 does

4. **Document differences** clearly
   - Create migration guides
   - Use comparison tables

5. **Monitor adoption** of new versions
   - Track which versions are being called
   - Plan deprecation based on usage

6. **Deprecate gracefully**
   - 12 months notice minimum for external APIs
   - Add deprecation headers
   - Provide migration support

---

## ⚠️ Common Mistakes

### ❌ Don't Do This

```csharp
// Wrong versioning method
options.ApiVersionReader = new QueryStringApiVersionReader();

// Wrong route (no version placeholder)
[Route("api/products")]

// Hardcoded version in path
path: 'v1/products'  // In APIM Bicep

// Sharing models between versions
public class Product { } // Used in both v1 and v2

// Not linking to Version Set
resource api '...' = {
  properties: {
    // Missing: apiVersionSetId
  }
}
```

### ✅ Do This Instead

```csharp
// Correct versioning method
options.ApiVersionReader = new UrlSegmentApiVersionReader();

// Correct route
[Route("v{version:apiVersion}/[controller]")]

// Correct APIM path
path: 'products'
apiVersion: 'v1'
apiVersionSetId: versionSet.id

// Separate models
public class ProductV1 { }
public class ProductV2 { }

// Always link to Version Set
apiVersionSetId: versionSet.id
```

---

## 🎯 Quick Decision Tree

```
Need to make an API change?
    │
    ├─ Breaking change? ──→ YES ──→ Create new version (v2, v3)
    │                                   │
    │                                   ├─ Create new controller/models
    │                                   ├─ Update APIM Version Set
    │                                   ├─ Create migration guide
    │                                   └─ Update tests
    │
    └─ Non-breaking? ──→ YES ──→ Create revision
                                      │
                                      ├─ Same controller/models
                                      ├─ Update revision number
                                      └─ Update tests
```

---

## 📞 Quick Command Reference

```bash
# Build and run locally
dotnet restore
dotnet run

# Download OpenAPI specs
curl https://localhost:7001/swagger/v1/swagger.json -o v1.json
curl https://localhost:7001/swagger/v2/swagger.json -o v2.json

# Deploy to APIM
az deployment group create \
  --resource-group your-rg \
  --template-file bicep/modules/api-version-set.bicep \
  --parameters @parameters.json

# Test versions
curl https://your-apim.azure-api.net/v1/products
curl https://your-apim.azure-api.net/v2/products
```

---

**Version:** 1.0
**Last Updated:** 2024
**Questions?** Contact architecture-team or check `/docs/`

---

**Print this page and keep it at your desk!** 📌

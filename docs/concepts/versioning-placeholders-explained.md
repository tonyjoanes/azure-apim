# Understanding {version} Placeholders in API Versioning

## The Confusion Explained

You'll often see this in C# API versioning:

```csharp
[Route("v{version:apiVersion}/products")]
```

And wonder: "Why the placeholder? Won't this create weird URLs?"

**Answer:** No! This is a **route template**, not a literal URL. Let me explain.

---

## How {version:apiVersion} Works

### What It Is

`{version:apiVersion}` is an **ASP.NET Core route template parameter** that gets **replaced at runtime** with the actual version number.

**At runtime, it becomes:**
```
/v1/products  (when version 1.0 is requested)
/v2/products  (when version 2.0 is requested)
```

**NOT:**
```
/v{version:apiVersion}/products  ❌ (never literal in URL)
```

### Why It's Used

This approach allows you to:

1. **Write DRY code** - One route template for all versions
2. **Let ASP.NET handle routing** - Automatic version matching
3. **Support multiple versions** - Controllers can specify which versions they support

### Example Flow

```csharp
// Controller V1
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public ActionResult<ProductV1> GetAll() { }
}

// Controller V2
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("2.0")]
    public ActionResult<ProductV2> GetAll() { }
}
```

**Request comes in:**
```
GET /v1/products
```

**ASP.NET Core routing:**
1. Sees `/v1/products`
2. Matches route template `v{version:apiVersion}/products`
3. Extracts `version = 1.0`
4. Routes to V1 controller
5. Calls V1 `GetAll()` method

**Result:** Client gets V1 response

---

## Does This Work With APIM Version Sets?

### ✅ YES! Perfectly!

Here's why they're compatible:

### 1. Actual URLs Generated

The C# API generates **real URLs**, not placeholder URLs:

```
Swagger v1 spec shows:
  /v1/products
  /v1/products/{id}

Swagger v2 spec shows:
  /v2/products
  /v2/products/{id}
```

### 2. APIM Sees Normal URLs

When you import the OpenAPI spec to APIM:

```json
// From v1 swagger.json
{
  "paths": {
    "/v1/products": {
      "get": { ... }
    }
  }
}

// From v2 swagger.json
{
  "paths": {
    "/v2/products": {
      "get": { ... }
    }
  }
}
```

APIM sees **normal versioned paths** - no placeholders!

### 3. Version Sets Work Normally

```bicep
// Create Version Set
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@...' = {
  properties: {
    displayName: 'Products API'
    versioningScheme: 'Segment'  // Works with /v1/, /v2/
  }
}

// Import v1 (from swagger that shows /v1/products)
resource apiV1 'Microsoft.ApiManagement/service/apis@...' = {
  properties: {
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id
    path: 'products'  // APIM adds /v1/ prefix
    // OpenAPI spec imported shows /v1/products
  }
}
```

**Result:** Everything works! ✅

---

## Common Misconceptions

### ❌ Misconception 1: "The placeholder is in the actual URL"

**Reality:**
```
What developers think: https://api.example.com/v{version:apiVersion}/products
What actually happens: https://api.example.com/v1/products
```

The placeholder is replaced before any HTTP response is sent.

### ❌ Misconception 2: "APIM can't handle route templates"

**Reality:** APIM never sees the route template. It only sees the final URLs in the OpenAPI spec:
```json
{
  "paths": {
    "/v1/products": { ... },  // Real path
    "/v2/products": { ... }   // Real path
  }
}
```

### ❌ Misconception 3: "I need to hardcode versions in routes"

**Bad approach:**
```csharp
// V1 Controller - hardcoded
[Route("v1/products")]
public class ProductsV1Controller : ControllerBase { }

// V2 Controller - hardcoded
[Route("v2/products")]
public class ProductsV2Controller : ControllerBase { }
```

**Problems:**
- Can't reuse code
- Manual routing
- Error-prone
- Doesn't work with API versioning framework

**Better approach:**
```csharp
// V1 Controller - with placeholder
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]
public class ProductsController : ControllerBase { }

// V2 Controller - same template!
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/products")]
public class ProductsController : ControllerBase { }
```

**Benefits:**
- DRY (Don't Repeat Yourself)
- Framework handles routing
- Type-safe versioning
- Works with API versioning tools

### ❌ Misconception 4: "This only works locally"

**Reality:** Works everywhere!
- ✅ Local development
- ✅ Swagger/OpenAPI generation
- ✅ Deployed to Azure App Service
- ✅ Behind APIM
- ✅ In Kubernetes
- ✅ Anywhere ASP.NET Core runs

---

## When NOT to Use Placeholders

### Don't use placeholders in:

#### 1. APIM Bicep Configuration

```bicep
// ❌ WRONG - Don't use placeholders in APIM
resource api 'Microsoft.ApiManagement/service/apis@...' = {
  properties: {
    path: 'v{version:apiVersion}/products'  // ❌ No!
  }
}

// ✅ CORRECT - Use static path
resource api 'Microsoft.ApiManagement/service/apis@...' = {
  properties: {
    apiVersion: 'v1'      // Specify version here
    path: 'products'      // Base path only
    apiVersionSetId: versionSet.id
  }
}
```

#### 2. OpenAPI Specs (Manual Creation)

```yaml
# ❌ WRONG - Don't use placeholders
paths:
  /v{version}/products:
    get:
      summary: Get products

# ✅ CORRECT - Specific version
paths:
  /v1/products:
    get:
      summary: Get products (v1)
```

#### 3. Documentation URLs

```markdown
❌ WRONG: Call https://api.example.com/v{version:apiVersion}/products
✅ CORRECT: Call https://api.example.com/v1/products or /v2/products
```

---

## The Right Way: End-to-End Example

### Step 1: C# API with Placeholders (Correct!)

```csharp
// Program.cs
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
})
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;  // 🔑 Replaces placeholder!
});

// V1 Controller
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]  // 👈 Placeholder here is correct!
public class ProductsController : ControllerBase
{
    [HttpGet]
    public ActionResult<ProductV1> GetAll() { }
}

// V2 Controller
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/products")]  // 👈 Same placeholder!
public class ProductsController : ControllerBase
{
    [HttpGet]
    public ActionResult<ProductV2> GetAll() { }
}
```

### Step 2: Generated OpenAPI Specs (No Placeholders!)

**What gets generated:**

`/swagger/v1/swagger.json`:
```json
{
  "paths": {
    "/v1/products": {           // 👈 Real URL, no placeholder!
      "get": {
        "operationId": "GetAll",
        "responses": { ... }
      }
    }
  }
}
```

`/swagger/v2/swagger.json`:
```json
{
  "paths": {
    "/v2/products": {           // 👈 Real URL, no placeholder!
      "get": {
        "operationId": "GetAll",
        "responses": { ... }
      }
    }
  }
}
```

### Step 3: APIM Version Set (No Placeholders!)

```bicep
// Version Set
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@...' = {
  name: 'products-versions'
  properties: {
    displayName: 'Products API'
    versioningScheme: 'Segment'
  }
}

// Import v1 with real paths from OpenAPI spec
resource apiV1 'Microsoft.ApiManagement/service/apis@...' = {
  name: 'products-v1'
  properties: {
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id
    path: 'products'
    format: 'openapi+json'
    value: loadTextContent('v1.json')  // Contains /v1/products
  }
}

// Import v2 with real paths from OpenAPI spec
resource apiV2 'Microsoft.ApiManagement/service/apis@...' = {
  name: 'products-v2'
  properties: {
    apiVersion: 'v2'
    apiVersionSetId: versionSet.id
    path: 'products'  // Same base path
    format: 'openapi+json'
    value: loadTextContent('v2.json')  // Contains /v2/products
  }
}
```

### Step 4: Result - Everything Works!

**In APIM Portal:**
```
Products API (Version Set)
├── Products API v1 (/v1/products)
└── Products API v2 (/v2/products)
```

**Client calls:**
```bash
# Call v1
curl https://apim.azure-api.net/v1/products

# Call v2
curl https://apim.azure-api.net/v2/products
```

---

## Why Use {version:apiVersion}?

### Benefits

#### 1. Single Route Template

```csharp
// Without placeholder - repetitive
[Route("v1/products")]  // V1 Controller
[Route("v2/products")]  // V2 Controller
[Route("v3/products")]  // V3 Controller

// With placeholder - DRY
[Route("v{version:apiVersion}/products")]  // All controllers use this
```

#### 2. Framework Integration

```csharp
// Framework knows about versions
[ApiVersion("1.0")]
[ApiVersion("2.0")]  // Can support multiple versions
[Route("v{version:apiVersion}/products")]
```

#### 3. Type Safety

```csharp
// Framework ensures version exists
[HttpGet]
[MapToApiVersion("1.0")]  // Compile-time check
public ActionResult<ProductV1> GetV1() { }

[HttpGet]
[MapToApiVersion("99.0")]  // Error if version not declared
public ActionResult<Product> Get() { }
```

#### 4. Swagger Generation

```csharp
// Automatically generates separate docs
foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
{
    options.SwaggerDoc(description.GroupName, ...);
    // Creates /swagger/v1/swagger.json, /swagger/v2/swagger.json
}
```

---

## Alternative Approaches (and Why They're Worse)

### Approach 1: Hardcoded Versions in Routes

```csharp
[Route("v1/products")]
public class ProductsV1Controller : ControllerBase { }

[Route("v2/products")]
public class ProductsV2Controller : ControllerBase { }
```

**Problems:**
- ❌ Can't reuse route templates
- ❌ No framework support
- ❌ Manual version management
- ❌ Error-prone
- ❌ Harder to maintain

### Approach 2: Query String Versioning

```csharp
[Route("products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public ActionResult<Product> Get([FromQuery] string version)
    {
        if (version == "1") return GetV1();
        if (version == "2") return GetV2();
    }
}
```

**Problems:**
- ❌ Manual version parsing
- ❌ Not visible in URL
- ❌ Harder to cache
- ❌ Poor APIM integration
- ❌ No compile-time checks

### Approach 3: Header Versioning

```csharp
[Route("products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public ActionResult<Product> Get([FromHeader(Name = "Api-Version")] string version)
    {
        // Manual version handling
    }
}
```

**Problems:**
- ❌ Not discoverable
- ❌ Harder to test
- ❌ Not visible in logs
- ❌ Poor Swagger support
- ❌ Difficult APIM integration

---

## Testing That It Works

### Test 1: Check Generated URLs

```bash
# Run your API locally
dotnet run

# Open Swagger UI
# https://localhost:7001

# Check dropdown - should show "V1" and "V2"

# Test v1 endpoint
curl https://localhost:7001/v1/products
# Should work! No placeholder in URL

# Test v2 endpoint
curl https://localhost:7001/v2/products
# Should work! No placeholder in URL

# Try with placeholder (should fail)
curl https://localhost:7001/v{version:apiVersion}/products
# 404 Not Found - proves placeholder isn't literal
```

### Test 2: Check OpenAPI Specs

```bash
# Download v1 spec
curl https://localhost:7001/swagger/v1/swagger.json > v1.json

# Check for placeholders
grep "{version" v1.json
# Should return nothing - no placeholders in generated spec!

# Check actual paths
grep "/v1/products" v1.json
# Should find them - real paths present!
```

### Test 3: Verify APIM Import

```bash
# After deploying to APIM
# Check APIM portal

# Both versions should be visible
# No "{version:apiVersion}" anywhere in APIM
# Clean /v1/products and /v2/products URLs
```

---

## Quick Troubleshooting

### Problem: Seeing {version:apiVersion} in Swagger

**Cause:** Missing `SubstituteApiVersionInUrl = true`

**Fix:**
```csharp
.AddApiExplorer(options =>
{
    options.SubstituteApiVersionInUrl = true;  // Add this!
});
```

### Problem: 404 when calling /v1/products

**Cause:** Version not properly configured

**Check:**
```csharp
// Controller must have ApiVersion attribute
[ApiVersion("1.0")]  // Must match "v1" in URL

// Operation must map to version
[MapToApiVersion("1.0")]  // Must be present
```

### Problem: APIM shows /v{version:apiVersion}/products

**Cause:** Manually creating API instead of importing OpenAPI

**Fix:** Import the generated OpenAPI spec, don't create manually

---

## Summary

### ✅ Use Placeholders In:
- C# route templates: `[Route("v{version:apiVersion}/products")]`
- That's it! Just in C# routes.

### ❌ Don't Use Placeholders In:
- APIM Bicep configurations
- Manual OpenAPI specs
- Documentation
- Client code
- Test URLs
- Any configuration outside C# code

### 🔑 Key Points:
1. `{version:apiVersion}` is a **route template**, not a literal URL
2. It gets **replaced at runtime** with actual version (v1, v2, etc.)
3. **OpenAPI specs show real URLs** (/v1/products), not placeholders
4. **APIM Version Sets work perfectly** with this approach
5. This is the **recommended approach** by Microsoft
6. It's **not weird or wrong** - it's the proper way to do URL versioning in ASP.NET Core

---

## Why People Use This

It's not weird or unnecessary - it's the **official Microsoft approach** for API versioning in ASP.NET Core:

- Part of `Asp.Versioning` package (formerly Microsoft.AspNetCore.Mvc.Versioning)
- Recommended in Microsoft docs
- Industry standard for .NET APIs
- Works seamlessly with OpenAPI/Swagger
- Compatible with APIM Version Sets
- Type-safe and maintainable

**Bottom Line:** Use `{version:apiVersion}` in your C# routes. It's correct, works perfectly with APIM, and is the recommended approach! ✅

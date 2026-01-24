# Versioned API - Complete Example

This is a **complete working example** showing how to implement API versioning that works correctly with Azure APIM.

## The Problem This Solves

If you've been struggling with:
- Only seeing v1 in APIM even though your API has multiple versions
- Swagger dropdown shows versions but APIM doesn't
- Not understanding how Version Sets work

**This example shows you exactly how to fix it!**

## What's Included

- ✅ Proper URL segment versioning (`/v1/products`, `/v2/products`)
- ✅ Separate Swagger documents per version
- ✅ V1 controller with basic functionality
- ✅ V2 controller with enhanced features
- ✅ Different models per version
- ✅ Ready to import to APIM with Version Sets

## Project Structure

```
VersionedAPI/
├── Controllers/
│   ├── V1/
│   │   └── ProductsController.cs    # Version 1 endpoints
│   └── V2/
│       └── ProductsController.cs    # Version 2 endpoints (enhanced)
├── Models/
│   └── Product.cs                   # ProductV1 and ProductV2 models
├── Program.cs                       # Versioning configuration
└── VersionedAPI.csproj             # Project file with versioning packages
```

## Running the API

### 1. Build and Run

```bash
cd api/VersionedAPI
dotnet restore
dotnet build
dotnet run
```

The API starts on:
- HTTPS: `https://localhost:7001`
- HTTP: `http://localhost:5001`

### 2. Access Swagger UI

Navigate to: `https://localhost:7001`

You'll see a dropdown at the top with **V1** and **V2** options!

### 3. Separate OpenAPI Specs

Each version has its own OpenAPI spec:

```
https://localhost:7001/swagger/v1/swagger.json  ← Version 1 spec
https://localhost:7001/swagger/v2/swagger.json  ← Version 2 spec
```

## API Versions

### Version 1 (v1) - Basic

**Endpoints:**
- `GET /v1/products` - Get all products
- `GET /v1/products/{id}` - Get product by ID
- `POST /v1/products` - Create product
- `PUT /v1/products/{id}` - Update product
- `DELETE /v1/products/{id}` - Delete product

**Response Model:**
```json
{
  "id": 1,
  "name": "Laptop",
  "price": 999.99
}
```

### Version 2 (v2) - Enhanced

**New Features in V2:**
- Product descriptions
- Categories
- Stock tracking
- Image URLs
- Search functionality
- Category filtering
- Stock updates

**Endpoints:**
- `GET /v2/products` - Get all products (with filters)
- `GET /v2/products/{id}` - Get product by ID
- `GET /v2/products/search?query=laptop` - **NEW:** Search products
- `GET /v2/products/category/{category}` - **NEW:** Get by category
- `POST /v2/products` - Create product (requires category)
- `PUT /v2/products/{id}` - Update product
- `PATCH /v2/products/{id}/stock` - **NEW:** Update stock
- `DELETE /v2/products/{id}` - Delete product

**Response Model:**
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

## Testing the Versions

### Test V1

```bash
# Get all products (v1)
curl https://localhost:7001/v1/products

# Get product by ID (v1)
curl https://localhost:7001/v1/products/1

# Create product (v1)
curl -X POST https://localhost:7001/v1/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Monitor","price":299.99}'
```

### Test V2

```bash
# Get all products with filters (v2)
curl "https://localhost:7001/v2/products?category=Electronics&minPrice=50"

# Search products (v2 only)
curl "https://localhost:7001/v2/products/search?query=laptop"

# Get by category (v2 only)
curl https://localhost:7001/v2/products/category/Electronics

# Create product (v2 - requires category)
curl -X POST https://localhost:7001/v2/products \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Monitor",
    "description":"4K Monitor",
    "price":299.99,
    "category":"Electronics",
    "stock":25
  }'

# Update stock (v2 only)
curl -X PATCH "https://localhost:7001/v2/products/1/stock?quantity=100"
```

## Deploying to APIM

### Step 1: Deploy API to Azure

Deploy this API to Azure App Service or Container Apps:

```bash
# Example: Deploy to App Service
az webapp create \
  --resource-group rg-apim-learning \
  --plan asp-versioned-api \
  --name versioned-api-app \
  --runtime "DOTNET|8.0"

dotnet publish -c Release
# ... deploy the published app
```

### Step 2: Download OpenAPI Specs

Once deployed, download the specs:

```bash
# Download v1 spec
curl https://versioned-api-app.azurewebsites.net/swagger/v1/swagger.json \
  -o ../../specs/products-v1.json

# Download v2 spec
curl https://versioned-api-app.azurewebsites.net/swagger/v2/swagger.json \
  -o ../../specs/products-v2.json
```

### Step 3: Deploy to APIM with Version Sets

Use the Bicep example:

```bash
az deployment group create \
  --resource-group rg-apim-learning \
  --template-file ../../bicep/examples/versioned-api-deployment.bicep \
  --parameters apimServiceName=your-apim-name \
               backendUrlV1=https://versioned-api-app.azurewebsites.net/v1 \
               backendUrlV2=https://versioned-api-app.azurewebsites.net/v2
```

### Step 4: Verify in APIM

Go to Azure Portal → APIM → APIs:

```
Products API (Version Set)
├── Products API v1  (/v1/products)
└── Products API v2  (/v2/products) [Current]
```

**Both versions are now visible!** ✅

## Key Configuration

### URL Segment Versioning (Required for APIM)

```csharp
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
    // This creates: /v1/products, /v2/products
    // NOT query string: /products?api-version=1
    // NOT header: Api-Version: 1
})
```

### Separate Swagger Docs (Required for APIM)

```csharp
builder.Services.AddSwaggerGen(options =>
{
    // Creates separate document for EACH version
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(description.GroupName, new OpenApiInfo { ... });
    }
});
```

### Version in Route Template

```csharp
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]  // {version:apiVersion} is replaced
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]  // Explicitly map to version
    public ActionResult<IEnumerable<ProductV1>> GetAll() { }
}
```

## Common Issues

### Issue 1: Only v1 shows in Swagger

**Problem:** Missing `GroupNameFormat` configuration

**Solution:**
```csharp
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";  // ← Add this!
})
```

### Issue 2: 404 on versioned routes

**Problem:** Missing `SubstituteApiVersionInUrl`

**Solution:**
```csharp
.AddApiExplorer(options =>
{
    options.SubstituteApiVersionInUrl = true;  // ← Add this!
})
```

### Issue 3: Can't find separate Swagger docs

**Problem:** Not creating docs for each version

**Solution:**
```csharp
// Add this in SwaggerGen configuration
foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
{
    options.SwaggerDoc(description.GroupName, ...);  // ← Add for each version!
}
```

## Differences Between Versions

| Feature | V1 | V2 |
|---------|----|----|
| Basic CRUD | ✅ | ✅ |
| Product fields | 3 fields | 6 fields |
| Search | ❌ | ✅ |
| Category filtering | ❌ | ✅ |
| Stock management | ❌ | ✅ |
| Enhanced responses | ❌ | ✅ |

## Next Steps

1. ✅ Run this API locally
2. ✅ Test both versions in Swagger UI
3. ✅ Download separate OpenAPI specs
4. ✅ Deploy to Azure
5. ✅ Create Version Set in APIM
6. ✅ Import both versions to APIM
7. ✅ Test through APIM gateway
8. 🎉 Both versions visible and working!

## Resources

- [Complete Versioning Guide](../../docs/concepts/versioning-complete-guide.md)
- [Version Set Bicep Module](../../bicep/modules/api-version-set.bicep)
- [Versioned API Bicep Module](../../bicep/modules/api-versioned.bicep)
- [Example Deployment](../../bicep/examples/versioned-api-deployment.bicep)
- [Microsoft Docs: API Versioning](https://learn.microsoft.com/aspnet/core/web-api/advanced/versioning)
- [APIM Versions](https://learn.microsoft.com/azure/api-management/api-management-versions)

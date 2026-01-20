# Sample API

A sample .NET 8 Web API project designed to demonstrate Azure API Management features.

## Overview

This is a simple RESTful API with two main resources:
- **Products** - Product catalog management
- **Users** - User management

The API includes:
- OpenAPI/Swagger documentation
- RESTful endpoints
- XML documentation
- Logging
- CORS support
- Health check endpoint

## Prerequisites

- .NET 8 SDK or later
- Visual Studio 2022, VS Code, or Rider

## Getting Started

### 1. Build the Project

```bash
cd api/SampleAPI
dotnet restore
dotnet build
```

### 2. Run the API

```bash
dotnet run
```

The API will start on:
- HTTPS: `https://localhost:7001`
- HTTP: `http://localhost:5001`

### 3. View Swagger UI

Navigate to: `https://localhost:7001/swagger`

## API Endpoints

### Health Check

```
GET /health
```

Returns API health status.

### Products API

```
GET    /api/products              # Get all products (with optional filters)
GET    /api/products/{id}         # Get product by ID
POST   /api/products              # Create new product
PUT    /api/products/{id}         # Update product
DELETE /api/products/{id}         # Delete product
```

**Query Parameters for GET /api/products:**
- `category` - Filter by category
- `minPrice` - Minimum price filter
- `maxPrice` - Maximum price filter

### Users API

```
GET    /api/users                 # Get all users
GET    /api/users/{id}            # Get user by ID
POST   /api/users                 # Create new user
DELETE /api/users/{id}            # Delete user
```

## Example Requests

### Get All Products

```bash
curl https://localhost:7001/api/products
```

### Get Products by Category

```bash
curl "https://localhost:7001/api/products?category=Electronics&minPrice=50"
```

### Create a Product

```bash
curl -X POST https://localhost:7001/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Product",
    "description": "Product description",
    "price": 99.99,
    "category": "Electronics",
    "stock": 100
  }'
```

### Create a User

```bash
curl -X POST https://localhost:7001/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "firstName": "New",
    "lastName": "User"
  }'
```

## Deploying to Azure

### Option 1: Azure App Service

```bash
# Create App Service
az webapp create \
  --resource-group rg-apim-learning \
  --plan asp-sample-api \
  --name sample-api-app \
  --runtime "DOTNET|8.0"

# Deploy
dotnet publish -c Release
cd bin/Release/net8.0/publish
zip -r deploy.zip .
az webapp deployment source config-zip \
  --resource-group rg-apim-learning \
  --name sample-api-app \
  --src deploy.zip
```

### Option 2: Azure Container Apps

```bash
# Build and push container
docker build -t sampleapi:latest .
docker tag sampleapi:latest myregistry.azurecr.io/sampleapi:latest
docker push myregistry.azurecr.io/sampleapi:latest

# Deploy to Container Apps
az containerapp create \
  --name sample-api \
  --resource-group rg-apim-learning \
  --environment my-environment \
  --image myregistry.azurecr.io/sampleapi:latest \
  --target-port 8080 \
  --ingress external
```

## Importing to APIM

### 1. Get the OpenAPI Specification

Once the API is running, download the OpenAPI spec:

```bash
curl https://localhost:7001/swagger/v1/swagger.json > openapi.json
```

### 2. Import to APIM via Azure Portal

1. Navigate to your APIM instance
2. Go to APIs
3. Click "Add API"
4. Select "OpenAPI"
5. Upload the `openapi.json` file
6. Configure:
   - Display name: Sample API
   - Name: sample-api
   - API URL suffix: sample
   - Backend URL: Your deployed API URL

### 3. Import via Bicep

```bicep
module sampleApi '../bicep/modules/api.bicep' = {
  name: 'sample-api-deployment'
  params: {
    apimServiceName: 'your-apim-name'
    apiName: 'sample-api'
    apiDisplayName: 'Sample API'
    apiDescription: 'Sample API for APIM demonstration'
    apiPath: 'sample'
    serviceUrl: 'https://your-api-url.azurewebsites.net'
    openApiSpec: loadTextContent('openapi.json')
    apiSpecFormat: 'openapi+json'
  }
}
```

## Project Structure

```
SampleAPI/
├── Controllers/
│   ├── ProductsController.cs    # Products endpoints
│   └── UsersController.cs       # Users endpoints
├── Models/
│   ├── Product.cs               # Product model
│   └── User.cs                  # User model
├── Properties/
│   └── launchSettings.json
├── appsettings.json
├── appsettings.Development.json
├── Program.cs                   # Application entry point
└── SampleAPI.csproj            # Project file
```

## Features Demonstrated

### OpenAPI Documentation

The API automatically generates OpenAPI (Swagger) documentation, which can be:
- Viewed in Swagger UI
- Downloaded as JSON/YAML
- Imported into APIM

### Logging

Uses ASP.NET Core logging:

```csharp
_logger.LogInformation("Getting all products");
_logger.LogWarning("Product with ID {ProductId} not found", id);
```

### CORS

Configured to allow all origins for development. Update for production:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("Production", policy =>
    {
        policy.WithOrigins("https://yourdomain.com")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

### Health Checks

Simple health check endpoint:

```
GET /health

Response:
{
  "status": "healthy",
  "timestamp": "2024-01-20T10:30:00Z",
  "version": "1.0.0"
}
```

## Testing

Use the `.http` files in the `/tests` directory to test the API:

```
GET https://localhost:7001/api/products
```

Or use the Swagger UI at `https://localhost:7001/swagger`

## Next Steps

1. Deploy the API to Azure App Service or Container Apps
2. Import to APIM using the OpenAPI specification
3. Configure APIM policies (rate limiting, caching, etc.)
4. Test through APIM gateway
5. Create products and subscriptions in APIM
6. Monitor with Application Insights

## Additional Resources

- [ASP.NET Core Web API Documentation](https://learn.microsoft.com/aspnet/core/web-api/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Azure App Service](https://learn.microsoft.com/azure/app-service/)

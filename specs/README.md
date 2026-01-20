# OpenAPI Specifications

This directory contains OpenAPI (Swagger) specifications for APIs that can be imported into Azure API Management.

## Files

- `sample-api.yaml` - Sample API specification (same as the C# Sample API)
- `weather-api.yaml` - Simple weather API example
- `petstore-api.yaml` - Classic Petstore API example

## Using OpenAPI Specs

### Import to APIM via Azure Portal

1. Navigate to your APIM instance in Azure Portal
2. Go to **APIs** section
3. Click **+ Add API**
4. Select **OpenAPI**
5. Choose:
   - **OpenAPI specification**: Upload file or provide URL
   - **Display name**: User-friendly name
   - **Name**: Internal identifier
   - **API URL suffix**: Path suffix (e.g., "weather")
6. Click **Create**

### Import via Azure CLI

```bash
az apim api import \
  --resource-group rg-apim-learning \
  --service-name your-apim-name \
  --path weather \
  --specification-format OpenApi \
  --specification-path weather-api.yaml \
  --api-id weather-api
```

### Import via Bicep

```bicep
module weatherApi '../bicep/modules/api.bicep' = {
  name: 'weather-api-deployment'
  params: {
    apimServiceName: 'your-apim-name'
    apiName: 'weather-api'
    apiDisplayName: 'Weather API'
    apiPath: 'weather'
    serviceUrl: 'https://api.openweathermap.org'
    openApiSpec: loadTextContent('weather-api.yaml')
    apiSpecFormat: 'openapi+json'
  }
}
```

## OpenAPI Best Practices

### 1. Complete Metadata

```yaml
openapi: 3.0.0
info:
  title: Your API
  version: 1.0.0
  description: Detailed description
  contact:
    name: API Support
    email: support@example.com
  license:
    name: MIT
```

### 2. Server URLs

```yaml
servers:
  - url: https://api.production.com
    description: Production server
  - url: https://api.staging.com
    description: Staging server
```

### 3. Security Schemes

```yaml
components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### 4. Reusable Components

```yaml
components:
  schemas:
    Error:
      type: object
      properties:
        code:
          type: integer
        message:
          type: string
  responses:
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
```

### 5. Request/Response Examples

```yaml
paths:
  /products:
    get:
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Product'
              examples:
                sample:
                  value:
                    - id: 1
                      name: Laptop
                      price: 999.99
```

## Validating OpenAPI Specs

### Online Validators

- [Swagger Editor](https://editor.swagger.io/)
- [OpenAPI.Tools](https://openapi.tools/)

### Command Line

```bash
# Using swagger-cli
npm install -g @apidevtools/swagger-cli
swagger-cli validate weather-api.yaml

# Using openapi-generator
openapi-generator validate -i weather-api.yaml
```

## Generating Code from OpenAPI

### Client SDKs

```bash
# Generate TypeScript client
openapi-generator generate \
  -i weather-api.yaml \
  -g typescript-axios \
  -o ./clients/typescript

# Generate C# client
openapi-generator generate \
  -i weather-api.yaml \
  -g csharp \
  -o ./clients/csharp
```

### Server Stubs

```bash
# Generate ASP.NET Core server
openapi-generator generate \
  -i weather-api.yaml \
  -g aspnetcore \
  -o ./server/aspnetcore
```

## Converting Between Formats

### YAML to JSON

```bash
# Using yq
yq eval -o=json weather-api.yaml > weather-api.json

# Using online converter
# https://www.convertjson.com/yaml-to-json.htm
```

### Swagger 2.0 to OpenAPI 3.0

```bash
# Using swagger2openapi
npm install -g swagger2openapi
swagger2openapi swagger2.json -o openapi3.yaml
```

## APIM-Specific Extensions

### x-ms-paths

For path parameter conflicts:

```yaml
x-ms-paths:
  /items/{id}?operation=delete:
    delete:
      operationId: DeleteItem
```

## Resources

- [OpenAPI Specification](https://swagger.io/specification/)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Swagger Editor](https://editor.swagger.io/)
- [APIM Import API Documentation](https://learn.microsoft.com/azure/api-management/import-api-from-oas)

# API Testing with .http Files

This directory contains `.http` files for testing APIs through Azure API Management.

## What are .http Files?

`.http` files (also known as HTTP files or REST Client files) allow you to:
- Write HTTP requests in plain text
- Execute requests directly in VS Code
- Store requests in version control
- Share with team members
- Automate API testing

## Prerequisites

Install the **REST Client** extension in Visual Studio Code:
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "REST Client"
4. Install the extension by Huachao Mao

## Configuration

Before testing, update the variables in each file:

```http
### Variables
@apimGateway = your-apim-name.azure-api.net
@subscriptionKey = your-subscription-key-here
```

## Available Test Files

### Core Tests
- `sample-api.http` - Test Sample API endpoints
- `products-api.http` - Test Products CRUD operations
- `users-api.http` - Test Users CRUD operations

### Authentication Tests
- `subscription-key.http` - Test with subscription keys
- `jwt-auth.http` - Test with JWT tokens
- `no-auth.http` - Test without authentication (should fail)

### Policy Tests
- `rate-limit.http` - Test rate limiting
- `caching.http` - Test response caching
- `transformation.http` - Test request/response transformation

### Monitoring Tests
- `health-check.http` - Test health endpoints
- `tracing.http` - Test with tracing enabled

## Running Tests

### Execute Single Request

1. Open `.http` file
2. Click "Send Request" above the request
3. View response in split window

### Execute All Requests

Right-click in file → Select "Send All Requests"

### Keyboard Shortcuts

- **Ctrl+Alt+R** (Cmd+Alt+R on Mac): Send request
- **Ctrl+Alt+C** (Cmd+Alt+C on Mac): Cancel request

## Request Format

Basic structure:

```http
### Request Description
GET https://api.example.com/endpoint
Header-Name: header-value
Another-Header: another-value

{
  "body": "for POST/PUT requests"
}
```

## Using Variables

Define variables at the top:

```http
### Variables
@baseUrl = your-apim.azure-api.net
@apiKey = abc123

### Use in requests
GET https://{{baseUrl}}/api/products
Ocp-Apim-Subscription-Key: {{apiKey}}
```

## Environment Variables

Create a `.env` file (gitignored):

```env
APIM_GATEWAY=your-apim.azure-api.net
SUBSCRIPTION_KEY=your-key-here
JWT_TOKEN=your-jwt-token
```

Use in `.http` files:

```http
@apimGateway = {{$dotenv APIM_GATEWAY}}
@subscriptionKey = {{$dotenv SUBSCRIPTION_KEY}}
```

## Response Handling

### View Response

Response appears in split window showing:
- Status code
- Headers
- Body (formatted JSON/XML)
- Response time

### Save Response

Right-click response → "Save Response" or "Save Response Body"

### Extract Values

Use variables from previous responses:

```http
### Create Product
POST https://{{apimGateway}}/api/products
Content-Type: application/json

{
  "name": "Test Product"
}

### Extract ID from response
@productId = {{$response.body.id}}

### Use extracted ID
GET https://{{apimGateway}}/api/products/{{productId}}
```

## Common Headers

### Subscription Key

```http
Ocp-Apim-Subscription-Key: your-subscription-key
```

### JWT Token

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Content Type

```http
Content-Type: application/json
Accept: application/json
```

### Custom Headers

```http
X-Request-Id: 12345
X-Correlation-Id: abc-def-ghi
```

### Tracing

```http
Ocp-Apim-Trace: true
```

## Testing Scenarios

### Success Cases

```http
### Get all products - should return 200
GET https://{{apimGateway}}/api/products
Ocp-Apim-Subscription-Key: {{subscriptionKey}}
```

### Error Cases

```http
### Missing subscription key - should return 401
GET https://{{apimGateway}}/api/products

### Invalid subscription key - should return 401
GET https://{{apimGateway}}/api/products
Ocp-Apim-Subscription-Key: invalid-key

### Not found - should return 404
GET https://{{apimGateway}}/api/products/99999
Ocp-Apim-Subscription-Key: {{subscriptionKey}}
```

### Rate Limiting

```http
### Send multiple requests quickly
### Should return 429 after limit exceeded

### Request 1
GET https://{{apimGateway}}/api/products
Ocp-Apim-Subscription-Key: {{subscriptionKey}}

### Request 2
GET https://{{apimGateway}}/api/products
Ocp-Apim-Subscription-Key: {{subscriptionKey}}

### ... repeat until rate limit hit
```

## Example Test File

```http
### Variables
@apimGateway = your-apim.azure-api.net
@subscriptionKey = your-subscription-key
@baseUrl = https://{{apimGateway}}

### Health Check
GET {{baseUrl}}/health
Ocp-Apim-Subscription-Key: {{subscriptionKey}}

### Get All Products
GET {{baseUrl}}/api/products
Ocp-Apim-Subscription-Key: {{subscriptionKey}}
Accept: application/json

### Get Product by ID
GET {{baseUrl}}/api/products/1
Ocp-Apim-Subscription-Key: {{subscriptionKey}}

### Create Product
POST {{baseUrl}}/api/products
Content-Type: application/json
Ocp-Apim-Subscription-Key: {{subscriptionKey}}

{
  "name": "New Product",
  "description": "Product description",
  "price": 99.99,
  "category": "Electronics",
  "stock": 100
}

### Update Product
PUT {{baseUrl}}/api/products/1
Content-Type: application/json
Ocp-Apim-Subscription-Key: {{subscriptionKey}}

{
  "name": "Updated Product",
  "description": "Updated description",
  "price": 89.99,
  "category": "Electronics",
  "stock": 150
}

### Delete Product
DELETE {{baseUrl}}/api/products/1
Ocp-Apim-Subscription-Key: {{subscriptionKey}}
```

## Best Practices

### 1. Use Variables

```http
### Good
@baseUrl = https://api.example.com
GET {{baseUrl}}/products

### Bad - hardcoded URLs
GET https://api.example.com/products
```

### 2. Separate Requests

```http
### Each request gets a description
### Get Product
GET {{baseUrl}}/products/1

### Update Product
PUT {{baseUrl}}/products/1
```

### 3. Version Control

```bash
# Commit .http files
git add tests/*.http
git commit -m "Add API tests"

# Don't commit secrets
# Use .env files (add to .gitignore)
```

### 4. Document Expected Results

```http
### Get Product - Expect 200 OK
GET {{baseUrl}}/products/1
Ocp-Apim-Subscription-Key: {{key}}

### Invalid ID - Expect 404 Not Found
GET {{baseUrl}}/products/99999
Ocp-Apim-Subscription-Key: {{key}}
```

### 5. Organize by Feature

```
tests/
├── authentication.http
├── products.http
├── users.http
├── rate-limiting.http
└── error-cases.http
```

## Troubleshooting

### Connection Refused
- Check APIM gateway URL
- Verify APIM instance is running
- Check network/firewall

### 401 Unauthorized
- Verify subscription key is correct
- Check key is not expired
- Ensure product/API requires subscription

### 429 Too Many Requests
- Rate limit exceeded
- Wait for renewal period
- Check rate limit policy

### 500 Internal Server Error
- Check backend service is running
- Review APIM logs
- Enable tracing for details

## Continuous Testing

### CI/CD Integration

Use tools like:
- **Newman** (Postman CLI)
- **REST Client CLI**
- **curl** scripts
- **Playwright** for HTTP testing

### Example GitHub Actions

```yaml
name: API Tests
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test APIs
        run: |
          # Convert .http to curl or use REST client
          npm install -g httpyac
          httpyac tests/*.http
```

## Next Steps

- [Authentication Methods](../docs/authentication/overview.md)
- [Policy Testing](../policies/examples/README.md)
- [Monitoring APIs](../docs/monitoring/overview.md)

## Resources

- [REST Client Documentation](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
- [HTTP Request Syntax](https://httpwg.org/specs/)
- [APIM Testing Guide](https://learn.microsoft.com/azure/api-management/api-management-howto-test-api)

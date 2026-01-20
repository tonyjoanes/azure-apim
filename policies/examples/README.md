# APIM Policy Examples

This directory contains practical policy examples for Azure API Management.

## Policy Structure

APIM policies are XML documents with four sections:

```xml
<policies>
    <inbound>
        <!-- Applied on incoming request -->
    </inbound>
    <backend>
        <!-- Applied before forwarding to backend -->
    </backend>
    <outbound>
        <!-- Applied on outgoing response -->
    </outbound>
    <on-error>
        <!-- Applied when an error occurs -->
    </on-error>
</policies>
```

## Policy Scopes

Policies can be applied at different levels:

1. **Global** - Applies to all APIs
2. **Product** - Applies to all APIs in a product
3. **API** - Applies to all operations in an API
4. **Operation** - Applies to a specific operation

## Policy Execution Order

```
Inbound:  Global → Product → API → Operation
Backend:  Operation → API → Product → Global
Outbound: Operation → API → Product → Global
On-Error: Operation → API → Product → Global
```

## Available Examples

### Security
- `rate-limit.xml` - Rate limiting and quotas
- `jwt-validation.xml` - JWT token validation
- `ip-filter.xml` - IP whitelisting/blacklisting
- `cors.xml` - CORS configuration
- `client-certificate.xml` - Client certificate validation

### Transformation
- `set-headers.xml` - Add/modify/remove headers
- `transform-json-to-xml.xml` - JSON to XML transformation
- `transform-xml-to-json.xml` - XML to JSON transformation
- `modify-response.xml` - Response modification

### Routing & Backend
- `set-backend-service.xml` - Dynamic backend routing
- `rewrite-url.xml` - URL rewriting
- `load-balancing.xml` - Backend load balancing
- `circuit-breaker.xml` - Circuit breaker pattern

### Caching
- `cache-response.xml` - Response caching
- `cache-lookup.xml` - Cache lookup

### Integration
- `send-request.xml` - Make HTTP requests
- `log-to-eventhub.xml` - Log to Event Hub
- `azure-keyvault.xml` - Retrieve secrets from Key Vault

### Error Handling
- `custom-error-response.xml` - Custom error messages
- `retry-policy.xml` - Retry failed requests
- `mock-response.xml` - Return mock responses

## Using Policies

### Via Azure Portal

1. Navigate to your APIM instance
2. Go to APIs → Select API → Design
3. Select **All operations** or specific operation
4. Click **</>** in the Inbound/Outbound/Backend processing section
5. Paste policy XML
6. Click **Save**

### Via Bicep

```bicep
module apiPolicy '../modules/policy.bicep' = {
  name: 'api-policy-deployment'
  params: {
    apimServiceName: 'your-apim-name'
    policyScope: 'api'
    apiName: 'sample-api'
    policyContent: loadTextContent('rate-limit.xml')
  }
}
```

### Via Azure CLI

```bash
az apim api policy create \
  --resource-group rg-apim-learning \
  --service-name your-apim-name \
  --api-id sample-api \
  --xml-policy @rate-limit.xml
```

## Policy Expressions

Policies support C# expressions with `@()`:

```xml
<set-header name="X-Request-Time" exists-action="override">
    <value>@(DateTime.UtcNow.ToString())</value>
</set-header>
```

### Available Context Objects

- `context.Request` - Request information
- `context.Response` - Response information
- `context.Api` - API information
- `context.Operation` - Operation information
- `context.User` - User information
- `context.Product` - Product information
- `context.Subscription` - Subscription information
- `context.Variables` - Custom variables

## Testing Policies

### 1. Test in Azure Portal

Use the **Test** tab to test policies without affecting production.

### 2. Enable Tracing

```xml
<inbound>
    <trace source="my-policy" severity="information">
        <message>@("Request received: " + context.Request.Url.Path)</message>
    </trace>
</inbound>
```

### 3. Use Postman/HTTP Files

Test with Ocp-Apim-Trace header:

```http
GET https://your-apim.azure-api.net/api/products
Ocp-Apim-Subscription-Key: your-key
Ocp-Apim-Trace: true
```

## Best Practices

1. **Keep policies simple** - Complex logic belongs in backend
2. **Use policy fragments** - Reuse common policy snippets
3. **Handle errors gracefully** - Always include on-error section
4. **Test thoroughly** - Test all scenarios before production
5. **Monitor performance** - Policies add latency
6. **Use named values** - Don't hardcode configuration
7. **Version control** - Keep policies in source control
8. **Document policies** - Add comments explaining logic

## Common Patterns

### 1. Authentication Flow

```xml
<inbound>
    <!-- Validate subscription key -->
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
        <openid-config url="https://login.microsoftonline.com/..." />
    </validate-jwt>

    <!-- Extract claims -->
    <set-variable name="userId" value="@(context.Request.Headers.GetValueOrDefault("Authorization","").AsJwt()?.Claims["sub"].FirstOrDefault())" />
</inbound>
```

### 2. Rate Limiting

```xml
<inbound>
    <rate-limit calls="10" renewal-period="60" />
    <quota calls="1000" renewal-period="86400" />
</inbound>
```

### 3. Request/Response Transformation

```xml
<inbound>
    <set-header name="X-Client-IP" exists-action="override">
        <value>@(context.Request.IpAddress)</value>
    </set-header>
</inbound>
<outbound>
    <set-header name="X-Powered-By" exists-action="delete" />
</outbound>
```

### 4. Caching

```xml
<inbound>
    <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
</inbound>
<outbound>
    <cache-store duration="3600" />
</outbound>
```

## Resources

- [Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Policy Expressions](https://learn.microsoft.com/azure/api-management/api-management-policy-expressions)
- [Policy Samples](https://github.com/Azure/api-management-policy-snippets)

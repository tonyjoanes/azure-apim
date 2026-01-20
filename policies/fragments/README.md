# Policy Fragments

Policy fragments are reusable policy snippets that can be shared across multiple APIs, operations, or products.

## What are Policy Fragments?

Policy fragments allow you to:
- **Reuse common policy logic** across multiple policies
- **Centralize policy management** - update once, apply everywhere
- **Simplify complex policies** - break down into manageable pieces
- **Maintain consistency** across APIs

## Benefits

1. **DRY Principle** - Don't Repeat Yourself
2. **Easier Maintenance** - Update in one place
3. **Consistency** - Same logic everywhere
4. **Modularity** - Mix and match fragments
5. **Versioning** - Version fragments independently

## Creating Policy Fragments

### Via Azure Portal

1. Navigate to your APIM instance
2. Go to **Policy fragments**
3. Click **+ Add**
4. Enter:
   - **Name**: Fragment identifier
   - **Description**: What it does
   - **Policy**: The fragment XML
5. Click **Save**

### Via Bicep

```bicep
resource fragment 'Microsoft.ApiManagement/service/policyFragments@2023-05-01-preview' = {
  parent: apimService
  name: 'add-request-id'
  properties: {
    description: 'Adds request ID header'
    value: '''
      <fragment>
        <set-variable name="requestId" value="@(Guid.NewGuid().ToString())" />
        <set-header name="X-Request-Id" exists-action="override">
          <value>@((string)context.Variables["requestId"])</value>
        </set-header>
      </fragment>
    '''
  }
}
```

## Using Policy Fragments

### In Policies

Use the `<include-fragment>` element:

```xml
<policies>
    <inbound>
        <base />
        <!-- Include a policy fragment -->
        <include-fragment fragment-id="add-request-id" />
        <include-fragment fragment-id="validate-api-key" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <include-fragment fragment-id="add-security-headers" />
    </outbound>
    <on-error>
        <base />
        <include-fragment fragment-id="error-handling" />
    </on-error>
</policies>
```

## Available Fragments

### Common Fragments

- `add-request-id.xml` - Adds unique request ID
- `add-security-headers.xml` - Adds security headers
- `validate-api-key.xml` - Validates API key from header
- `error-response.xml` - Standardized error response
- `log-request.xml` - Logs request details
- `remove-sensitive-headers.xml` - Removes sensitive headers

## Fragment Structure

Fragments must be wrapped in `<fragment>` tags:

```xml
<fragment>
    <!-- Your policy elements here -->
    <set-header name="X-Example" exists-action="override">
        <value>example-value</value>
    </set-header>
</fragment>
```

## Example Fragments

### 1. Add Request ID

```xml
<fragment>
    <set-variable name="requestId" value="@(Guid.NewGuid().ToString())" />
    <set-header name="X-Request-Id" exists-action="override">
        <value>@((string)context.Variables["requestId"])</value>
    </set-header>
</fragment>
```

### 2. Security Headers

```xml
<fragment>
    <set-header name="X-Content-Type-Options" exists-action="override">
        <value>nosniff</value>
    </set-header>
    <set-header name="X-Frame-Options" exists-action="override">
        <value>DENY</value>
    </set-header>
    <set-header name="Strict-Transport-Security" exists-action="override">
        <value>max-age=31536000; includeSubDomains</value>
    </set-header>
</fragment>
```

### 3. Error Response

```xml
<fragment>
    <return-response>
        <set-status code="@(context.Response.StatusCode)" />
        <set-body>@{
            return new JObject(
                new JProperty("error", context.LastError?.Reason ?? "Unknown"),
                new JProperty("message", context.LastError?.Message ?? "An error occurred"),
                new JProperty("timestamp", DateTime.UtcNow.ToString("o")),
                new JProperty("requestId", context.Variables.GetValueOrDefault<string>("requestId", ""))
            ).ToString();
        }</set-body>
    </return-response>
</fragment>
```

### 4. Logging

```xml
<fragment>
    <trace source="api-request" severity="information">
        <message>@{
            return new JObject(
                new JProperty("method", context.Request.Method),
                new JProperty("url", context.Request.Url.Path),
                new JProperty("ip", context.Request.IpAddress),
                new JProperty("timestamp", DateTime.UtcNow.ToString("o"))
            ).ToString();
        }</message>
    </trace>
</fragment>
```

## Best Practices

1. **Keep fragments focused** - One responsibility per fragment
2. **Use descriptive names** - Clear purpose
3. **Add descriptions** - Document what it does
4. **Version fragments** - Use versioning for breaking changes
5. **Test thoroughly** - Test fragment before using widely
6. **Don't overuse** - Balance between reuse and complexity

## Common Use Cases

### Standard Headers Across All APIs

Create fragments for:
- Request ID generation
- Security headers
- CORS headers
- API versioning headers

### Consistent Error Handling

Create fragments for:
- Error response formatting
- Error logging
- Custom error messages

### Authentication

Create fragments for:
- JWT validation
- API key validation
- Client certificate validation

### Monitoring

Create fragments for:
- Request logging
- Performance tracking
- Custom metrics

## Fragment Variables

Fragments can access all context variables:

```xml
<fragment>
    <set-header name="X-API-Name" exists-action="override">
        <value>@(context.Api.Name)</value>
    </set-header>
    <set-header name="X-Product-Name" exists-action="override">
        <value>@(context.Product?.Name ?? "No Product")</value>
    </set-header>
</fragment>
```

## Nesting Fragments

Fragments can include other fragments:

```xml
<fragment>
    <include-fragment fragment-id="add-request-id" />
    <include-fragment fragment-id="log-request" />
</fragment>
```

## Resources

- [Policy Fragments Documentation](https://learn.microsoft.com/azure/api-management/policy-fragments)
- [Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)

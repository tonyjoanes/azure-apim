# APIM Examples and Scenarios

This directory contains practical examples and common scenarios for Azure API Management.

## Example Scenarios

### 1. Simple API Gateway

**Scenario**: Expose a backend API through APIM with basic subscription key authentication.

**Steps**:
1. Deploy backend API
2. Import OpenAPI spec to APIM
3. Create product with subscription
4. Test with subscription key

**Use Case**: Internal APIs, simple integrations

---

### 2. Rate-Limited Public API

**Scenario**: Public API with rate limiting to prevent abuse.

**Configuration**:
```xml
<policies>
    <inbound>
        <rate-limit calls="10" renewal-period="60" />
        <quota calls="1000" renewal-period="86400" />
    </inbound>
</policies>
```

**Use Case**: Public APIs, free tiers

---

### 3. JWT-Protected Microservices

**Scenario**: Protect microservices with JWT token validation.

**Configuration**:
```xml
<policies>
    <inbound>
        <validate-jwt header-name="Authorization">
            <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
            <audiences>
                <audience>api://your-api</audience>
            </audiences>
        </validate-jwt>
    </inbound>
</policies>
```

**Use Case**: Microservices, SPA applications

---

### 4. Backend Transformation

**Scenario**: Transform REST API to different format without modifying backend.

**Configuration**:
```xml
<policies>
    <inbound>
        <set-header name="X-Custom-Header" exists-action="override">
            <value>custom-value</value>
        </set-header>
    </inbound>
    <outbound>
        <set-body>@{
            var response = context.Response.Body.As<JObject>();
            return new JObject(
                new JProperty("data", response),
                new JProperty("timestamp", DateTime.UtcNow),
                new JProperty("version", "1.0")
            ).ToString();
        }</set-body>
    </outbound>
</policies>
```

**Use Case**: Legacy API modernization, API versioning

---

### 5. Multi-Backend Routing

**Scenario**: Route to different backends based on request path or headers.

**Configuration**:
```xml
<policies>
    <inbound>
        <choose>
            <when condition="@(context.Request.Url.Path.StartsWith("/v1/"))">
                <set-backend-service base-url="https://api-v1.example.com" />
            </when>
            <when condition="@(context.Request.Url.Path.StartsWith("/v2/"))">
                <set-backend-service base-url="https://api-v2.example.com" />
            </when>
            <otherwise>
                <set-backend-service base-url="https://api-latest.example.com" />
            </otherwise>
        </choose>
    </inbound>
</policies>
```

**Use Case**: API versioning, A/B testing

---

### 6. Response Caching

**Scenario**: Cache GET requests to reduce backend load.

**Configuration**:
```xml
<policies>
    <inbound>
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false">
            <vary-by-query-parameter>category</vary-by-query-parameter>
            <vary-by-query-parameter>page</vary-by-query-parameter>
        </cache-lookup>
    </inbound>
    <outbound>
        <cache-store duration="3600" />
    </outbound>
</policies>
```

**Use Case**: Read-heavy APIs, static data

---

### 7. Mock API for Development

**Scenario**: Return mock responses for development/testing.

**Configuration**:
```xml
<policies>
    <inbound>
        <mock-response status-code="200" content-type="application/json">
            <set-body>{
                "id": 1,
                "name": "Mock Product",
                "price": 99.99
            }</set-body>
        </mock-response>
    </inbound>
</policies>
```

**Use Case**: Frontend development, backend not ready

---

### 8. IP Whitelisting for Partner APIs

**Scenario**: Restrict access to specific IP addresses.

**Configuration**:
```xml
<policies>
    <inbound>
        <ip-filter action="allow">
            <address>13.66.201.169</address>
            <address-range from="192.168.1.0" to="192.168.1.255" />
        </ip-filter>
    </inbound>
</policies>
```

**Use Case**: B2B integrations, partner APIs

---

### 9. Request Logging to Event Hub

**Scenario**: Log all requests to Azure Event Hub for analytics.

**Configuration**:
```xml
<policies>
    <inbound>
        <log-to-eventhub logger-id="event-hub-logger">
            @{
                return new JObject(
                    new JProperty("method", context.Request.Method),
                    new JProperty("url", context.Request.Url.Path),
                    new JProperty("ip", context.Request.IpAddress),
                    new JProperty("timestamp", DateTime.UtcNow)
                ).ToString();
            }
        </log-to-eventhub>
    </inbound>
</policies>
```

**Use Case**: Analytics, compliance, audit trails

---

### 10. Circuit Breaker Pattern

**Scenario**: Protect backend from overload with circuit breaker.

**Configuration**:
```bicep
resource backend 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  properties: {
    url: 'https://backend.example.com'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 3
            interval: 'PT60S'
            statusCodeRanges: [
              { min: 500, max: 599 }
            ]
          }
          tripDuration: 'PT60S'
        }
      ]
    }
  }
}
```

**Use Case**: Resilient systems, fault tolerance

---

## Common Patterns

### Authentication Patterns

1. **API Key Only** - Simplest, subscription key
2. **JWT Only** - Token-based, modern apps
3. **API Key + JWT** - Both required for extra security
4. **Client Certificate** - mTLS for high security
5. **IP + API Key** - Geographic restrictions

### Rate Limiting Patterns

1. **Global Limit** - Same for all users
2. **Per Subscription** - Different per product tier
3. **Per IP** - Limit by client IP
4. **Per User** - Based on JWT claims
5. **Burst + Sustained** - Combine rate-limit and quota

### Caching Patterns

1. **Simple Cache** - Cache all GET requests
2. **Vary by Query** - Different cache per query params
3. **Vary by Header** - Cache per Accept-Language, etc.
4. **User-Specific** - Cache per user/subscription
5. **Time-Based** - Different durations per endpoint

### Error Handling Patterns

1. **Custom Error Messages** - User-friendly errors
2. **Retry Logic** - Auto-retry failed requests
3. **Fallback Response** - Return default on error
4. **Circuit Breaker** - Fail fast on backend issues
5. **Graceful Degradation** - Reduced functionality

## Implementation Guides

### Setting Up a New API

1. **Design API** - Create OpenAPI specification
2. **Deploy Backend** - Deploy to Azure App Service/Functions
3. **Import to APIM** - Import OpenAPI spec
4. **Configure Policies** - Add rate limiting, auth, etc.
5. **Create Products** - Group APIs into products
6. **Create Subscriptions** - Generate keys for testing
7. **Test** - Use .http files to test
8. **Monitor** - Enable Application Insights
9. **Document** - Customize Developer Portal
10. **Deploy** - Move to production

### Migrating Existing API to APIM

1. **Document Current API** - Create OpenAPI spec
2. **Deploy APIM** - Set up APIM instance
3. **Import API** - Import spec to APIM
4. **Test Directly** - Test APIM → Backend
5. **Add Policies** - Gradually add policies
6. **Parallel Testing** - Test both old and new endpoints
7. **Update Clients** - Switch to APIM gateway
8. **Monitor** - Watch for issues
9. **Decommission** - Remove direct backend access
10. **Optimize** - Add caching, rate limiting, etc.

## Real-World Scenarios

### E-commerce API

- **Products API**: Public, rate-limited, cached
- **Cart API**: Authenticated, not cached
- **Payment API**: Highly secured, client cert
- **Admin API**: IP whitelisted, internal only

### SaaS API Platform

- **Free Tier**: 100 calls/day, limited endpoints
- **Basic Tier**: 10,000 calls/day, all endpoints
- **Premium Tier**: 1M calls/day, priority support
- **Enterprise Tier**: Unlimited, dedicated support

### IoT Data Ingestion

- **Device Registration**: One-time, secured
- **Telemetry Upload**: High volume, minimal processing
- **Command & Control**: Low latency, authenticated
- **Analytics Query**: Cached, rate-limited

## Testing Strategies

### Development
- Use mock responses
- Test with Developer tier APIM
- Enable detailed tracing
- Use .http files for quick testing

### Staging
- Mirror production policies
- Test with realistic load
- Validate all scenarios
- Check Application Insights

### Production
- Monitor error rates
- Track rate limit hits
- Review slow requests
- Alert on anomalies

## Best Practices Summary

1. **Start Simple** - Basic auth, then add complexity
2. **Use Products** - Organize APIs logically
3. **Apply Policies** - Use policy fragments for reuse
4. **Monitor Everything** - Application Insights essential
5. **Cache Wisely** - Cache static/slow data
6. **Rate Limit** - Protect backend from abuse
7. **Version APIs** - Plan for API evolution
8. **Document APIs** - Keep Developer Portal updated
9. **Test Thoroughly** - Use .http files
10. **Secure Secrets** - Use Key Vault for sensitive data

## Resources

- [APIM Policies](../policies/examples/README.md)
- [Authentication Methods](../docs/authentication/overview.md)
- [Testing Guide](../tests/README.md)
- [Bicep Templates](../bicep/README.md)

## Contributing

Add your own examples and scenarios! Common patterns help everyone learn faster.

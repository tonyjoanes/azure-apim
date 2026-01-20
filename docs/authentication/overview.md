# Authentication in Azure APIM

Azure API Management supports multiple authentication and authorization mechanisms to secure your APIs.

## Authentication Methods

### 1. Subscription Keys (Default)
- Simple API key-based authentication
- Automatically generated for products
- Passed in header or query string
- Good for: Simple scenarios, internal APIs

### 2. OAuth 2.0 / OpenID Connect
- Industry-standard authorization framework
- Token-based authentication
- Supports Azure AD, third-party providers
- Good for: User delegation, modern apps

### 3. JWT Token Validation
- Validate JSON Web Tokens
- Extract and use claims
- Azure AD, Auth0, custom issuers
- Good for: Microservices, SPA applications

### 4. Client Certificates
- Mutual TLS (mTLS) authentication
- Certificate-based identity
- High security
- Good for: B2B integrations, high-security scenarios

### 5. Basic Authentication
- Username and password
- Simple but less secure
- Should use HTTPS
- Good for: Legacy systems

### 6. Managed Identity
- Azure AD service identity
- No credentials in code
- Secure backend access
- Good for: Azure-to-Azure communication

## Authentication Flow Comparison

```mermaid
graph TB
    subgraph "Subscription Key"
        C1[Client] -->|Request + Key| G1[APIM]
        G1 -->|Validate| G1
        G1 -->|Forward| B1[Backend]
    end

    subgraph "OAuth 2.0"
        C2[Client] -->|1. Request Token| IDP[Identity Provider]
        IDP -->|2. Token| C2
        C2 -->|3. Request + Token| G2[APIM]
        G2 -->|4. Validate Token| G2
        G2 -->|5. Forward| B2[Backend]
    end

    subgraph "Client Certificate"
        C3[Client] -->|Request + Cert| G3[APIM]
        G3 -->|Validate Cert| G3
        G3 -->|Forward| B3[Backend]
    end
```

## Choosing an Authentication Method

| Method | Security | Complexity | Use Case |
|--------|----------|------------|----------|
| Subscription Key | Low | Low | Internal APIs, testing |
| OAuth 2.0 | High | High | User-facing apps |
| JWT Validation | High | Medium | Modern microservices |
| Client Certificates | Very High | High | B2B, high-security |
| Basic Auth | Low | Low | Legacy systems |
| Managed Identity | High | Low | Azure services |

## Combining Authentication Methods

You can combine multiple methods:

```xml
<policies>
    <inbound>
        <!-- Require subscription key AND JWT token -->
        <validate-jwt header-name="Authorization">
            <!-- JWT configuration -->
        </validate-jwt>
        <!-- Subscription key is validated automatically -->
    </inbound>
</policies>
```

## Security Best Practices

### 1. Always Use HTTPS
Never send credentials over HTTP:
```xml
<choose>
    <when condition="@(context.Request.Url.Scheme != "https")">
        <return-response>
            <set-status code="403" reason="Forbidden" />
            <set-body>HTTPS required</set-body>
        </return-response>
    </when>
</choose>
```

### 2. Rotate Keys Regularly
- Subscription keys: Regenerate periodically
- JWT signing keys: Rotate signing certificates
- Client certificates: Renew before expiration

### 3. Use Named Values for Secrets
Never hardcode secrets in policies:
```xml
<!-- Bad -->
<set-header name="X-API-Key" exists-action="override">
    <value>hardcoded-secret-key</value>
</set-header>

<!-- Good -->
<set-header name="X-API-Key" exists-action="override">
    <value>{{backend-api-key}}</value>
</set-header>
```

### 4. Implement Rate Limiting
Protect against brute force:
```xml
<rate-limit calls="10" renewal-period="60" />
```

### 5. Log Authentication Failures
Monitor for security incidents:
```xml
<on-error>
    <choose>
        <when condition="@(context.LastError.Reason == "Unauthorized")">
            <trace source="auth-failure">
                <message>@("Failed auth from: " + context.Request.IpAddress)</message>
            </trace>
        </when>
    </choose>
</on-error>
```

### 6. Principle of Least Privilege
- Grant minimum required permissions
- Use products to group APIs by access level
- Separate dev/test/prod subscriptions

## Authentication Headers

### Subscription Key

Default header name:
```
Ocp-Apim-Subscription-Key: your-subscription-key
```

Or query parameter:
```
?subscription-key=your-subscription-key
```

Custom header (configured in product):
```
X-API-Key: your-subscription-key
```

### Bearer Token (JWT)

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Basic Authentication

```
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
```

### Client Certificate

Certificate sent via TLS handshake, accessed in policy:
```xml
<set-variable name="clientCert" value="@(context.Request.Certificate)" />
```

## Next Steps

- [Subscription Keys](subscription-keys.md)
- [OAuth 2.0 Setup](oauth2.md)
- [JWT Validation](jwt-validation.md)
- [Client Certificates](client-certificates.md)
- [Managed Identity](managed-identity.md)
- [API Keys Guide](api-keys.md)

## Resources

- [APIM Authentication Policies](https://learn.microsoft.com/azure/api-management/api-management-policies#authentication-policies)
- [OAuth 2.0 Authorization](https://learn.microsoft.com/azure/api-management/api-management-howto-oauth2)
- [Client Certificates](https://learn.microsoft.com/azure/api-management/api-management-howto-mutual-certificates)

# API Versioning Guidelines

**Version:** 1.0
**Last Updated:** 2024
**Status:** Proposed
**Owner:** Architecture Team

---

## Executive Summary

These guidelines establish a standardized approach to API versioning that ensures seamless integration with Azure API Management (APIM) and provides clear version visibility to API consumers.

**Key Requirements:**
- ✅ Use URL path versioning (`/v1/resource`, `/v2/resource`)
- ✅ Generate separate OpenAPI specifications per version
- ✅ Configure APIM Version Sets for all versioned APIs
- ✅ Follow semantic versioning for version numbers
- ✅ Document breaking changes clearly

---

## 1. Scope

### These guidelines apply to:
- ✅ All new REST APIs exposed through Azure APIM
- ✅ Existing APIs when creating new versions
- ✅ Internal and external-facing APIs
- ✅ APIs developed in C#, Python, Node.js, or other languages

### Exceptions:
- APIs not exposed through APIM (internal-only microservices)
- Legacy APIs in maintenance mode (no new versions planned)
- Experimental/prototype APIs (must graduate to follow guidelines)

**Exception Process:** Request exception via architecture review board with business justification.

---

## 2. Versioning Strategy

### 2.1 When to Create a New Version

Create a **new major version** when making **breaking changes**:

| Breaking Change | Example | Action |
|----------------|---------|--------|
| Removing fields | Removing `phoneNumber` from User | Create v2 |
| Renaming fields | `userId` → `id` | Create v2 |
| Changing field types | `age: string` → `age: number` | Create v2 |
| Changing HTTP methods | `POST /users` → `PUT /users` | Create v2 |
| Removing endpoints | Delete `DELETE /users/{id}` | Create v2 |
| Required fields | Making `email` required | Create v2 |
| Response structure | `{ data: [] }` → `{ items: [] }` | Create v2 |
| Authentication changes | Add mandatory auth header | Create v2 |

### 2.2 When to Create a Revision (NOT a new version)

Use **revisions** for **non-breaking changes**:

| Non-Breaking Change | Example | Action |
|--------------------|---------|--------|
| Adding optional fields | Add optional `middleName` | Revision |
| Adding endpoints | Add `GET /users/{id}/preferences` | Revision |
| Bug fixes | Fix date format inconsistency | Revision |
| Performance improvements | Optimize query performance | Revision |
| Documentation updates | Improve API descriptions | Revision |
| Adding response codes | Add 429 rate limit response | Revision |
| Deprecation warnings | Add deprecation header | Revision |

### 2.3 Version Numbering

Follow **semantic versioning** for major versions:

```
Format: v{major}
Examples: v1, v2, v3

NOT: v1.0, v1.1, api-v1, version-1
```

**Rationale:**
- Simple and clear
- Works well with URL paths
- Revisions handle minor changes

---

## 3. Technical Implementation

### 3.1 URL Structure (MANDATORY)

**Required Format:**
```
https://{apim-gateway}/{version}/{resource}

Examples:
✅ https://api.example.com/v1/products
✅ https://api.example.com/v2/users
✅ https://api.example.com/v1/orders/{orderId}
```

**Not Allowed:**
```
❌ https://api.example.com/products?api-version=1
❌ https://api.example.com/products (with Api-Version: 1 header)
❌ https://api.example.com/api/v1/products (don't add /api prefix)
```

**Rationale:**
- Most visible and discoverable
- Best APIM support
- SEO-friendly and cacheable
- Standard industry practice

### 3.2 C# Implementation (ASP.NET Core)

**Required NuGet Packages:**
```xml
<PackageReference Include="Asp.Versioning.Http" Version="8.0.0" />
<PackageReference Include="Asp.Versioning.Mvc.ApiExplorer" Version="8.0.0" />
```

**Required Configuration in Program.cs:**
```csharp
// 1. Add API Versioning
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;

    // REQUIRED: Use URL segment versioning
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
})
.AddMvc()
.AddApiExplorer(options =>
{
    // REQUIRED: Format version as 'v1', 'v2', etc.
    options.GroupNameFormat = "'v'VVV";

    // REQUIRED: Replace {version:apiVersion} in routes
    options.SubstituteApiVersionInUrl = true;
});

// 2. Generate Separate Swagger Documents per Version
var apiVersionDescriptionProvider = builder.Services
    .BuildServiceProvider()
    .GetRequiredService<IApiVersionDescriptionProvider>();

builder.Services.AddSwaggerGen(options =>
{
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(description.GroupName, new OpenApiInfo
        {
            Title = $"My API {description.ApiVersion}",
            Version = description.ApiVersion.ToString(),
            Description = description.IsDeprecated
                ? "This version is deprecated"
                : "Current API version"
        });
    }
});

// 3. Expose Swagger Endpoints per Version
app.UseSwaggerUI(options =>
{
    foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
    {
        options.SwaggerEndpoint(
            $"/swagger/{description.GroupName}/swagger.json",
            description.GroupName.ToUpperInvariant()
        );
    }
});
```

**Required Controller Configuration:**
```csharp
// Version 1 Controller
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
    }
}

// Version 2 Controller
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
    }
}
```

**✅ Checklist for C# Implementation:**
- [ ] Asp.Versioning packages installed
- [ ] `UrlSegmentApiVersionReader` configured
- [ ] `SubstituteApiVersionInUrl = true`
- [ ] Separate Swagger doc per version
- [ ] Route template uses `v{version:apiVersion}`
- [ ] Controllers decorated with `[ApiVersion("X.0")]`
- [ ] Operations have `[MapToApiVersion("X.0")]`

### 3.3 APIM Configuration (Bicep)

**Required: Create Version Set First**
```bicep
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apimService
  name: 'my-api-versions'
  properties: {
    displayName: 'My API'
    description: 'My API with multiple versions'
    versioningScheme: 'Segment'  // URL path versioning
  }
}
```

**Required: Link Each Version to Version Set**
```bicep
// Import Version 1
resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: 'my-api-v1'
  properties: {
    displayName: 'My API v1'
    apiVersion: 'v1'                        // Version identifier
    apiVersionSetId: versionSet.id          // CRITICAL: Link to version set
    path: 'myapi'                           // Base path (NOT v1/myapi)
    serviceUrl: 'https://backend.azure.net/v1'
    subscriptionRequired: true
    protocols: ['https']
  }
}

// Import Version 2
resource apiV2 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: 'my-api-v2'
  properties: {
    displayName: 'My API v2'
    apiVersion: 'v2'                        // Different version
    apiVersionSetId: versionSet.id          // SAME version set
    path: 'myapi'                           // SAME base path
    serviceUrl: 'https://backend.azure.net/v2'
    subscriptionRequired: true
    protocols: ['https']
    isCurrent: true                         // Mark as current version
  }
}
```

**✅ Checklist for APIM:**
- [ ] Version Set created
- [ ] Each API version has `apiVersion` property
- [ ] Each API version has `apiVersionSetId` pointing to version set
- [ ] All versions use same base `path`
- [ ] Current version marked with `isCurrent: true`

---

## 4. OpenAPI Specifications

### 4.1 Separate Specs Required

**Generate separate OpenAPI specification for each version:**

```
✅ Correct:
/swagger/v1/swagger.json  → Spec for v1 only
/swagger/v2/swagger.json  → Spec for v2 only

❌ Wrong:
/swagger/swagger.json     → Combined spec (can't distinguish versions)
```

### 4.2 OpenAPI Metadata

Each spec must include proper version information:

```json
{
  "openapi": "3.0.1",
  "info": {
    "title": "My API v1",
    "version": "1.0",
    "description": "Version 1 of My API"
  },
  "servers": [
    {
      "url": "https://api.example.com/v1",
      "description": "Production v1"
    }
  ]
}
```

### 4.3 Importing to APIM

**Process:**
1. Download separate OpenAPI specs per version
2. Create Version Set in APIM (once)
3. Import each spec as separate API
4. Link each API to the Version Set

**Never:** Import a combined spec - APIM won't understand multiple versions

---

## 5. Version Lifecycle Management

### 5.1 Version States

| State | Description | Actions |
|-------|-------------|---------|
| **Development** | In progress, not public | Dev/test environments only |
| **Current** | Recommended version | Default for new integrations |
| **Supported** | Maintained, not recommended | Bug fixes only |
| **Deprecated** | Scheduled for removal | No new features, announce sunset date |
| **Retired** | No longer available | Returns 410 Gone |

### 5.2 Deprecation Process

**Timeline:** Minimum 12 months notice for external APIs, 6 months for internal

**Steps:**

**T-12 months (External) / T-6 months (Internal):**
1. Announce deprecation via:
   - API changelog
   - Email to registered consumers
   - Developer portal notice
   - Release notes

2. Update API responses with deprecation headers:
```xml
<set-header name="X-API-Deprecated" exists-action="override">
    <value>true</value>
</set-header>
<set-header name="X-API-Sunset" exists-action="override">
    <value>2025-12-31T23:59:59Z</value>
</set-header>
<set-header name="Link" exists-action="override">
    <value>&lt;https://api.example.com/v2/resource&gt;; rel="successor-version"</value>
</set-header>
```

3. Update OpenAPI spec:
```json
{
  "info": {
    "version": "1.0",
    "description": "⚠️ DEPRECATED: This version will be retired on 2025-12-31. Please migrate to v2."
  }
}
```

**T-6 months:**
- Send reminder emails
- Monitor usage metrics
- Reach out to high-volume consumers

**T-3 months:**
- Final warning emails
- Reduce rate limits (optional)
- Update documentation

**T-1 month:**
- Last chance notification
- Prepare retirement deployment

**T-Day (Retirement):**
- Return 410 Gone with migration information
- Monitor for issues
- Provide migration support

**Policy for Retired APIs:**
```xml
<policies>
    <inbound>
        <return-response>
            <set-status code="410" reason="Gone" />
            <set-header name="X-API-Retired" exists-action="override">
                <value>true</value>
            </set-header>
            <set-body>@{
                return new JObject(
                    new JProperty("error", "API Version Retired"),
                    new JProperty("message", "Version 1 was retired on 2025-12-31"),
                    new JProperty("migration_guide", "https://docs.example.com/migration/v1-to-v2"),
                    new JProperty("current_version", "v2"),
                    new JProperty("current_url", "https://api.example.com/v2/resource")
                ).ToString();
            }</set-body>
        </return-response>
    </inbound>
</policies>
```

### 5.3 Support Windows

| API Tier | Support Window | Deprecation Notice |
|----------|----------------|-------------------|
| **Public External** | 24 months minimum | 12 months |
| **Partner APIs** | 18 months minimum | 9 months |
| **Internal APIs** | 12 months minimum | 6 months |
| **Experimental** | No guarantee | 3 months |

---

## 6. Testing Requirements

### 6.1 Version-Specific Tests

Each version must have:
- ✅ Separate test suite
- ✅ Contract tests validating OpenAPI spec
- ✅ Integration tests through APIM
- ✅ Backwards compatibility tests (when applicable)

### 6.2 Test Structure

```
tests/
├── v1/
│   ├── products.test.ts
│   └── users.test.ts
├── v2/
│   ├── products.test.ts
│   └── users.test.ts
└── versioning.test.ts  # Tests version-specific behavior
```

### 6.3 .http Files

Provide `.http` files for manual testing:
```
tests/
├── v1-products.http
├── v2-products.http
└── README.md
```

---

## 7. Documentation Requirements

### 7.1 API Documentation

Each version requires:
- [ ] OpenAPI specification
- [ ] Migration guide from previous version
- [ ] Changelog highlighting differences
- [ ] Code examples for common operations
- [ ] Deprecation timeline (if applicable)

### 7.2 Version Comparison Matrix

**Example:**

| Feature | v1 | v2 | Notes |
|---------|----|----|-------|
| Get all products | ✅ | ✅ | v2 adds filtering |
| Product fields | 3 fields | 6 fields | v2 adds description, category, stock |
| Search | ❌ | ✅ | New in v2 |
| Filtering | ❌ | ✅ | By category, price, stock |
| Pagination | ❌ | ✅ | New in v2 |
| Response format | Simple | Enhanced | v2 includes metadata |

### 7.3 Migration Guides

**Required sections:**
1. **Overview** - What changed and why
2. **Breaking Changes** - List all breaking changes
3. **New Features** - What's new in this version
4. **Deprecated Features** - What's being phased out
5. **Migration Steps** - Step-by-step guide
6. **Code Examples** - Before/after comparisons
7. **Testing** - How to validate migration
8. **Support** - Where to get help

---

## 8. Governance & Compliance

### 8.1 Review Gates

**Before deploying a new version:**
- [ ] Architecture review approved
- [ ] Breaking changes documented
- [ ] Migration guide created
- [ ] Tests passing (>95% coverage)
- [ ] OpenAPI spec validated
- [ ] APIM Version Set configured
- [ ] Consumer notification sent (if breaking changes)
- [ ] Documentation updated

### 8.2 PR Checklist

Add to your pull request template:

```markdown
## API Versioning Checklist (if applicable)

If this PR changes API contract:

- [ ] Is this a breaking change?
  - [ ] Yes → New version created (v2, v3, etc.)
  - [ ] No → Revision updated
- [ ] C# versioning configured correctly
  - [ ] UrlSegmentApiVersionReader used
  - [ ] Separate Swagger doc generated
  - [ ] Route uses v{version:apiVersion}
- [ ] APIM Version Set configured
  - [ ] Version Set exists or created
  - [ ] API linked to Version Set
  - [ ] Bicep templates updated
- [ ] Documentation updated
  - [ ] OpenAPI spec updated
  - [ ] Migration guide created (if new version)
  - [ ] Changelog updated
- [ ] Tests added/updated
  - [ ] Version-specific tests
  - [ ] Integration tests through APIM
```

### 8.3 Metrics & Monitoring

**Track these metrics:**

| Metric | Target | Review Frequency |
|--------|--------|-----------------|
| APIs following guidelines | 100% of new APIs | Monthly |
| Deprecated API usage | Decreasing trend | Weekly |
| Version adoption rate | >50% on current within 6 months | Monthly |
| Breaking changes per year | Minimize | Quarterly |
| Support tickets related to versioning | Decreasing | Monthly |

---

## 9. Migration Path for Existing APIs

### 9.1 Existing APIs NOT Following Guidelines

**For APIs without proper versioning:**

**Option A: Next Breaking Change**
- Continue current API as-is until next breaking change needed
- When breaking change required, implement as v2 following guidelines
- Current API becomes "v1" (implicit)
- No immediate migration required

**Option B: Proactive Migration**
- Current API designated as v1
- Create v2 following guidelines (even if identical)
- Gradual consumer migration
- Timeline: 6-12 months

**Recommendation:** Option A for stable APIs, Option B for actively evolving APIs

### 9.2 Existing APIs Using Different Versioning

**For APIs using query string or header versioning:**

**Migration Steps:**
1. Continue existing versioning for current consumers
2. Implement URL path versioning for new version
3. Announce deprecation of old versioning scheme
4. Provide migration window (12 months minimum)
5. Retire old versioning scheme

**Example:**
```
Current:  /products?api-version=1 (deprecated)
New:      /v2/products (recommended)

Both work during migration period
After 12 months: /products?api-version=1 returns 410 Gone
```

### 9.3 Priority Order

**High Priority (Migrate within 3 months):**
- Public external APIs with active development
- APIs about to add breaking changes
- APIs causing consumer confusion

**Medium Priority (Migrate within 6 months):**
- Partner/B2B APIs
- Internal APIs with external exposure planned

**Low Priority (Migrate when convenient):**
- Stable internal APIs
- APIs in maintenance mode
- Experimental APIs

---

## 10. Support & Resources

### 10.1 Templates & Examples

**Available resources:**
- C# project template: `/api/VersionedAPI/`
- Bicep modules: `/bicep/modules/api-version-set.bicep`
- Complete example: `/bicep/examples/versioned-api-deployment.bicep`
- Test templates: `/tests/versioned-api.http`
- Documentation examples: `/docs/concepts/`

### 10.2 Getting Help

**For questions or issues:**

| Issue Type | Contact | Response Time |
|------------|---------|--------------|
| Guidelines clarification | Architecture team | 24 hours |
| Implementation help | Platform team | 48 hours |
| APIM configuration | DevOps team | 24 hours |
| Emergency/blocking issue | #api-support Slack channel | 4 hours |

### 10.3 Training & Onboarding

**Available training:**
- Self-paced guide: `/docs/concepts/versioning-complete-guide.md`
- Troubleshooting guide: `/docs/concepts/versioning-troubleshooting.md`
- Video walkthrough: [Link to recording]
- Office hours: Fridays 2-3 PM
- 1:1 pairing: Request via Slack

---

## 11. Exceptions & Edge Cases

### 11.1 When Guidelines Don't Apply

**Valid exceptions:**
- GraphQL APIs (different versioning model)
- WebSocket/SignalR APIs (different constraints)
- File upload/download endpoints (may need special handling)
- Webhook/callback endpoints (consumer-defined URLs)

**Request exception via:** Architecture review with justification

### 11.2 Hybrid Scenarios

**If you must support multiple versioning schemes:**
- Prefer URL path as primary
- Other schemes as fallback for backwards compatibility
- Document clearly in OpenAPI spec
- Plan migration to URL path only

---

## 12. FAQ

### Q: Do all APIs need versioning?
**A:** No. APIs that will never have breaking changes don't need versioning. However, adding v1 from the start makes future versioning easier.

### Q: Can we start without a version and add it later?
**A:** Not recommended. Adding versioning later is a breaking change itself. Better to start with v1.

### Q: What if we have many minor changes?
**A:** Use revisions for non-breaking changes. Only increment major version for breaking changes.

### Q: How do we handle experimental APIs?
**A:** Use `/preview/` or `/beta/` prefix instead of version number. Clearly document "no SLA, may change without notice."

### Q: Can different endpoints have different versions?
**A:** No. Version applies to entire API, not individual endpoints. If needed, split into separate APIs.

### Q: What about database versions?
**A:** Separate concern. API version doesn't have to match database schema version. Use API versioning for contract, database migrations for schema.

### Q: How do we version authentication?
**A:** Authentication changes are breaking changes requiring new API version. Consider versioning auth separately if it affects multiple APIs.

### Q: What if a consumer refuses to migrate?
**A:** Follow deprecation timeline. If critical customer, evaluate business case for extended support (at additional cost).

---

## 13. Appendix

### A. Complete C# Example

See: `/api/VersionedAPI/` for complete working example with v1 and v2.

### B. Bicep Templates

- Version Set: `/bicep/modules/api-version-set.bicep`
- Versioned API: `/bicep/modules/api-versioned.bicep`
- Complete deployment: `/bicep/examples/versioned-api-deployment.bicep`

### C. Testing Examples

See: `/tests/versioned-api.http` for comprehensive test suite.

### D. Troubleshooting Guide

See: `/docs/concepts/versioning-troubleshooting.md` for solutions to common problems.

---

## 14. Guidelines Approval

**Proposed by:** Architecture Team
**Review Period:** [Start Date] - [End Date]
**Approved by:**
- [ ] Architecture Review Board
- [ ] Development Team Leads
- [ ] Product Management
- [ ] DevOps Team

**Effective Date:** [Date]

**Review Schedule:** Quarterly, or as needed when issues arise

**Feedback:** Submit via [Process/Channel]

---

## Document Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | [Date] | Initial version | [Name] |
|  |  |  |  |

---

**Questions or suggestions?** Contact the Architecture team or submit feedback via [channel/process].

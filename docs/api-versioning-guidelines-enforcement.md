# API Versioning Guidelines - Mandatory Standards

**Status:** APPROVED
**Enforcement:** MANDATORY for all new APIs
**Effective Date:** [Date]

---

## 🔒 Mandatory Requirements

These are **NOT suggestions** - they are **requirements** for all APIs:

### 1. URL Path Versioning (MANDATORY)

**Required Format:**
```
✅ MUST:  /v1/products, /v2/products
❌ NEVER: /products?api-version=1
❌ NEVER: /products (with Api-Version header)
```

**Why Mandatory:**
- Only method that works reliably with APIM Version Sets
- Most visible and discoverable
- Industry standard
- Cacheable
- SEO-friendly

**No Exceptions Without Architecture Approval**

---

### 2. Route Template Pattern (MANDATORY)

**Required Pattern in C#:**
```csharp
✅ MUST USE:
[Route("v{version:apiVersion}/[controller]")]

❌ NEVER USE:
[Route("v1/[controller]")]  // Hardcoded version
[Route("api/v{version:apiVersion}/[controller]")]  // Extra /api prefix
[Route("{version:apiVersion}/[controller]")]  // Missing 'v' prefix
```

**Why This Pattern:**
- **Consistency**: All teams use same pattern
- **Framework Support**: Works with Asp.Versioning
- **DRY Principle**: One template for all versions
- **Type Safety**: Compile-time version checking
- **Automatic Generation**: Swagger docs per version

**This Is The Standard - Not Optional**

---

### 3. Required Configuration (MANDATORY)

**Program.cs MUST include:**

```csharp
// REQUIRED: These exact settings
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;

    // MANDATORY: URL segment versioning ONLY
    options.ApiVersionReader = new UrlSegmentApiVersionReader();

    // ❌ FORBIDDEN: Query string or header versioning
    // options.ApiVersionReader = new QueryStringApiVersionReader();
    // options.ApiVersionReader = new HeaderApiVersionReader();
})
.AddMvc()
.AddApiExplorer(options =>
{
    // MANDATORY: Format as 'v1', 'v2', etc.
    options.GroupNameFormat = "'v'VVV";

    // MANDATORY: Replace {version:apiVersion} placeholder
    options.SubstituteApiVersionInUrl = true;
});
```

**Why These Exact Settings:**
- Ensures consistent behavior across all APIs
- `UrlSegmentApiVersionReader` - Only approved method
- `SubstituteApiVersionInUrl = true` - Required for proper URL generation
- `GroupNameFormat = "'v'VVV"` - Standardized version format

---

### 4. Controller Pattern (MANDATORY)

**Required Controller Structure:**

```csharp
// ✅ CORRECT - Use this pattern
namespace MyAPI.Controllers.V1;

[ApiController]
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public ActionResult<ProductV1> GetAll() { }
}

// ✅ CORRECT - V2 controller
namespace MyAPI.Controllers.V2;

[ApiController]
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/[controller]")]  // Same route template
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("2.0")]
    public ActionResult<ProductV2> GetAll() { }
}
```

**Key Requirements:**
- ✅ Separate namespaces per version (V1, V2)
- ✅ `[ApiVersion("X.0")]` attribute
- ✅ `[Route("v{version:apiVersion}/[controller]")]` pattern
- ✅ `[MapToApiVersion("X.0")]` on all operations
- ✅ Version-specific models (ProductV1, ProductV2)

**What's Forbidden:**

```csharp
// ❌ WRONG - Hardcoded version in route
[Route("v1/products")]

// ❌ WRONG - Missing version placeholder
[Route("products")]

// ❌ WRONG - Not using [controller] placeholder
[Route("v{version:apiVersion}/products")]  // Should use [controller]

// ❌ WRONG - Shared models between versions
public class Product { }  // Used by both v1 and v2

// ❌ WRONG - Missing MapToApiVersion
[HttpGet]  // Missing [MapToApiVersion("1.0")]
public ActionResult Get() { }
```

---

## 📋 PR Checklist (Enforced)

**All PRs modifying APIs must check these boxes:**

### API Versioning Compliance

- [ ] **Route pattern**: Uses `[Route("v{version:apiVersion}/[controller]")]`
- [ ] **No hardcoded versions**: No `[Route("v1/...")]` patterns
- [ ] **Version reader**: `UrlSegmentApiVersionReader` configured
- [ ] **URL substitution**: `SubstituteApiVersionInUrl = true` set
- [ ] **Controller attributes**: Has `[ApiVersion("X.0")]`
- [ ] **Operation mapping**: All operations have `[MapToApiVersion("X.0")]`
- [ ] **Separate models**: Version-specific models (e.g., ProductV1, ProductV2)
- [ ] **Namespace separation**: Controllers in V1, V2 namespaces
- [ ] **Swagger generation**: Separate docs per version configured
- [ ] **Tests**: Version-specific test suite included

### APIM Integration (if applicable)

- [ ] **Version Set**: Exists or created in APIM
- [ ] **API linked**: `apiVersionSetId` configured
- [ ] **Correct path**: Uses base path only (no version prefix)
- [ ] **Bicep updated**: Infrastructure code reflects changes

### Documentation

- [ ] **Migration guide**: Created if breaking changes
- [ ] **Changelog**: Updated with version differences
- [ ] **OpenAPI spec**: Generated and tested

**PRs failing these checks will be REJECTED**

---

## 🚫 Anti-Patterns (Forbidden)

### These Patterns Are NOT Allowed

#### 1. Hardcoded Versions

```csharp
// ❌ FORBIDDEN
[Route("v1/products")]
public class ProductsControllerV1 : ControllerBase { }

[Route("v2/products")]
public class ProductsControllerV2 : ControllerBase { }
```

**Why Forbidden:**
- Not using versioning framework
- Can't leverage Asp.Versioning features
- Inconsistent with team standard
- Harder to maintain

**Consequence:** PR rejected, must refactor

#### 2. Query String Versioning

```csharp
// ❌ FORBIDDEN
options.ApiVersionReader = new QueryStringApiVersionReader("api-version");
// URLs: /products?api-version=1
```

**Why Forbidden:**
- Poor APIM integration
- Not visible in URL
- Caching issues
- Not discoverable

**Consequence:** PR rejected, must use URL path

#### 3. Header Versioning

```csharp
// ❌ FORBIDDEN
options.ApiVersionReader = new HeaderApiVersionReader("Api-Version");
// Header: Api-Version: 1
```

**Why Forbidden:**
- Not discoverable
- Poor Swagger support
- Difficult APIM integration
- Not visible in logs

**Consequence:** PR rejected, must use URL path

#### 4. Multiple Versioning Schemes

```csharp
// ❌ FORBIDDEN
options.ApiVersionReader = ApiVersionReader.Combine(
    new UrlSegmentApiVersionReader(),
    new QueryStringApiVersionReader(),
    new HeaderApiVersionReader()
);
```

**Why Forbidden:**
- Creates confusion
- Inconsistent behavior
- Harder to support
- Not necessary

**Consequence:** PR rejected, use URL path only

#### 5. Shared Models Between Versions

```csharp
// ❌ FORBIDDEN
public class Product { }  // Used by both V1 and V2

[ApiVersion("1.0")]
public class ProductsControllerV1 : ControllerBase
{
    public ActionResult<Product> Get() { }  // Wrong
}

[ApiVersion("2.0")]
public class ProductsControllerV2 : ControllerBase
{
    public ActionResult<Product> Get() { }  // Wrong
}
```

**Why Forbidden:**
- Breaking changes affect both versions
- Can't evolve models independently
- Coupling between versions
- Defeats purpose of versioning

**Consequence:** PR rejected, create separate models

**Required Fix:**
```csharp
// ✅ CORRECT
public class ProductV1 { }
public class ProductV2 { }

[ApiVersion("1.0")]
public class ProductsControllerV1 : ControllerBase
{
    public ActionResult<ProductV1> Get() { }  // Correct
}

[ApiVersion("2.0")]
public class ProductsControllerV2 : ControllerBase
{
    public ActionResult<ProductV2> Get() { }  // Correct
}
```

---

## 🎯 Why Enforce Consistency?

### The Problems We're Solving

**Without Enforcement:**
```
Team A: URL path versioning      (/v1/products)
Team B: Query string versioning  (/products?v=1)
Team C: Header versioning        (Api-Version: 1)
Team D: Hardcoded routes         (/v1/products, no framework)
Team E: No versioning            (/products, hope for best)
```

**Result:**
- 😕 Consumers confused by different patterns
- 📞 Support team doesn't know what to expect
- 🐛 APIM integration broken for some teams
- 📚 Documentation inconsistent
- ⏱️ Time wasted explaining differences

**With Enforcement:**
```
All Teams: URL path with {version:apiVersion} pattern
```

**Result:**
- ✅ Consistent consumer experience
- ✅ APIM Version Sets work for everyone
- ✅ Easy to support and document
- ✅ New developers onboard quickly
- ✅ Infrastructure code reusable

---

## 📐 The Standard Pattern

**This Is The Only Approved Pattern:**

### Complete Example

```csharp
// Program.cs
using Asp.Versioning;
using Asp.Versioning.ApiExplorer;

var builder = WebApplication.CreateBuilder(args);

// STANDARD CONFIGURATION - Copy This
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
})
.AddMvc()
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});

// STANDARD SWAGGER - Copy This
var provider = builder.Services.BuildServiceProvider()
    .GetRequiredService<IApiVersionDescriptionProvider>();

builder.Services.AddSwaggerGen(options =>
{
    foreach (var description in provider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(description.GroupName, new OpenApiInfo
        {
            Title = $"My API {description.ApiVersion}",
            Version = description.ApiVersion.ToString(),
            Description = description.IsDeprecated
                ? "⚠️ This version is deprecated"
                : "Current API version"
        });
    }
});

app.UseSwaggerUI(options =>
{
    foreach (var description in provider.ApiVersionDescriptions)
    {
        options.SwaggerEndpoint(
            $"/swagger/{description.GroupName}/swagger.json",
            description.GroupName.ToUpperInvariant()
        );
    }
});
```

```csharp
// Controllers/V1/ProductsController.cs
namespace MyAPI.Controllers.V1;

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
```

```csharp
// Controllers/V2/ProductsController.cs
namespace MyAPI.Controllers.V2;

[ApiController]
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("2.0")]
    public ActionResult<IEnumerable<ProductV2>> GetAll()
    {
        // V2 implementation
    }
}
```

**Use This Exact Pattern - Don't Deviate**

---

## 🔍 Enforcement Mechanisms

### 1. PR Template (Required)

All API PRs must complete this section:

```markdown
## API Versioning Checklist

I confirm this PR follows the mandatory versioning standards:

- [ ] Uses `[Route("v{version:apiVersion}/[controller]")]` pattern
- [ ] Uses `UrlSegmentApiVersionReader` only
- [ ] Has `SubstituteApiVersionInUrl = true`
- [ ] Separate controllers per version (V1, V2 namespaces)
- [ ] Separate models per version (ProductV1, ProductV2)
- [ ] All operations have `[MapToApiVersion("X.0")]`
- [ ] Separate Swagger docs generated per version
- [ ] Tested both versions independently

If any box is unchecked, explain why or this PR will be rejected.
```

### 2. Code Review (Mandatory Checks)

Reviewers MUST verify:

1. ✅ Route pattern matches standard
2. ✅ No hardcoded versions
3. ✅ No query string or header versioning
4. ✅ Version-specific models used
5. ✅ Proper namespace separation
6. ✅ All operations mapped to versions

**Reviewers: Do not approve PRs that don't comply**

### 3. Automated Checks (Recommended)

Add to CI/CD pipeline:

```yaml
# Example: Check for anti-patterns
- name: Verify Versioning Pattern
  run: |
    # Check for hardcoded versions
    if grep -r '\[Route("v[0-9]' ./Controllers/; then
      echo "ERROR: Hardcoded version found in route"
      exit 1
    fi

    # Check for query string versioning
    if grep -r 'QueryStringApiVersionReader' ./Program.cs; then
      echo "ERROR: Query string versioning not allowed"
      exit 1
    fi

    # Check for header versioning
    if grep -r 'HeaderApiVersionReader' ./Program.cs; then
      echo "ERROR: Header versioning not allowed"
      exit 1
    fi
```

### 4. Architecture Review Gate

**Required for:**
- First versioned API from a team
- Any deviation from standard
- New API projects

**Process:**
1. Submit architecture review request
2. Review code against standards
3. Verify APIM integration plan
4. Approve or request changes

---

## 📊 Compliance Tracking

### Metrics

**Track monthly:**
- % of new APIs following standards
- PRs rejected for non-compliance
- Teams fully compliant
- Support tickets due to versioning issues

**Targets:**
- 100% of new APIs compliant by Month 3
- Zero support tickets related to versioning confusion
- All teams trained and certified

### Reporting

**Monthly dashboard:**
```
API Versioning Compliance Report

New APIs This Month: 12
  - Compliant:      11 (92%) ✅
  - Non-compliant:   1 (8%)  ❌

PRs Rejected:        2
  - Hardcoded versions: 1
  - Query string:       1

Teams Fully Compliant: 8/10 (80%)

Action Required:
  - Team X: Migrate legacy APIs
  - Team Y: Complete training
```

---

## 🎓 Training & Certification

### Required Training

**All developers MUST complete:**
1. Read versioning guidelines
2. Review example code in `/api/VersionedAPI/`
3. Complete hands-on exercise
4. Pass versioning quiz (80% required)

### Hands-On Exercise

**Assignment:**
1. Create new API with 2 versions
2. Use correct route pattern
3. Generate separate Swagger docs
4. Deploy to test APIM
5. Verify both versions visible

**Submission:** PR for review

**Pass Criteria:**
- All mandatory standards followed
- Both versions work in APIM
- Tests passing

### Certification

**Developers are certified when they:**
- ✅ Complete training
- ✅ Pass quiz
- ✅ Submit passing exercise
- ✅ Have 1 compliant API in production

**Certification required before:**
- Creating new APIs
- Leading API development
- Reviewing API PRs

---

## 🚀 Getting Started Template

**Copy this template for all new APIs:**

```bash
# Use the approved template
git clone [internal-repo]/api-versioning-template
cd api-versioning-template

# Update project name
# Update namespaces
# Add your business logic
# Deploy

# Template includes:
# ✅ Correct configuration
# ✅ Standard route patterns
# ✅ Example V1 and V2 controllers
# ✅ Swagger setup
# ✅ Tests
# ✅ Bicep for APIM
# ✅ All mandatory standards
```

**Template Location:** `/api/VersionedAPI/` (in this repo)

---

## ⚖️ Exception Process

### Requesting an Exception

**Valid reasons:**
- Technical limitation (rare)
- Third-party integration requirement
- Regulatory requirement
- Grandfather existing API temporarily

**Not valid reasons:**
- "We prefer query strings"
- "We already built it differently"
- "Too much work to change"
- "Our team likes it this way"

### Exception Request Template

```markdown
## Versioning Standards Exception Request

API Name: [name]
Team: [team]
Requested Deviation: [what you want to do differently]

Business Justification: [why this is necessary]

Technical Justification: [why standard won't work]

Impact Analysis:
- Consumer impact: [...]
- APIM integration: [...]
- Support burden: [...]
- Documentation: [...]

Mitigation Plan: [how to minimize issues]

Duration: [temporary or permanent]

Approvals Required:
- [ ] Team Lead
- [ ] Architect
- [ ] Product Owner
```

**Approval Authority:** Architecture Review Board

**Timeline:** 2 weeks for decision

---

## 📞 Support & Questions

### Getting Help

**For questions:**
- Slack: #api-versioning-standards
- Email: architecture-team@company.com
- Office Hours: Fridays 2-3 PM

**For exceptions:**
- Submit exception request
- Attend architecture review
- Present business case

**For training:**
- Self-service: Read docs
- Instructor-led: Monthly sessions
- 1:1 pairing: By request

---

## 📅 Rollout Timeline

### Phase 1: Immediate (Now)
- ✅ Guidelines approved
- ✅ Standards documented
- ✅ Template available
- ✅ Training materials ready

### Phase 2: Month 1
- ✅ All new APIs MUST follow standards
- ✅ PR checks enforced
- ✅ Training sessions running
- ❌ Existing APIs: No changes required yet

### Phase 3: Months 2-3
- ✅ Teams begin migrating existing APIs
- ✅ Certification program launched
- ✅ Monthly compliance reporting

### Phase 4: Month 6
- ✅ All active APIs compliant
- ✅ All developers certified
- ✅ 100% new API compliance
- ✅ Zero versioning-related support tickets

---

## 🎯 Success Looks Like

**In 6 months:**
- Every new API follows the standard pattern
- All teams trained and certified
- APIM Version Sets working everywhere
- Consistent consumer experience
- Zero confusion about how to version APIs
- Documentation clear and unified
- Support tickets about versioning: Zero
- Onboarding time for new developers: Faster

**This is achievable with enforcement!**

---

## Summary: The Non-Negotiables

| Standard | Requirement | No Exceptions |
|----------|-------------|---------------|
| **Versioning Method** | URL path only | ✅ Mandatory |
| **Route Pattern** | `v{version:apiVersion}/[controller]` | ✅ Mandatory |
| **Version Reader** | `UrlSegmentApiVersionReader` only | ✅ Mandatory |
| **URL Substitution** | `SubstituteApiVersionInUrl = true` | ✅ Mandatory |
| **Separate Models** | Version-specific (V1, V2) | ✅ Mandatory |
| **Controller Attributes** | `[ApiVersion("X.0")]` | ✅ Mandatory |
| **Operation Mapping** | `[MapToApiVersion("X.0")]` | ✅ Mandatory |
| **Swagger Docs** | Separate per version | ✅ Mandatory |
| **APIM Version Sets** | All versioned APIs | ✅ Mandatory |
| **PR Checklist** | Complete before merge | ✅ Mandatory |

**These are not suggestions. These are requirements.**

---

**Version:** 1.0
**Status:** APPROVED AND ENFORCED
**Questions?** architecture-team@company.com

**Compliance is mandatory. No exceptions without approval.**

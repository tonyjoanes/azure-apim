# API Versioning in Azure APIM

## The Problem

You're likely experiencing this common issue:

```
C# API with versioning → Generates Swagger with version dropdown → Import to APIM → Only v1 shows! 😞
```

**Why?** APIM needs **Version Sets** to understand that multiple APIs are versions of the same API.

## APIM Versioning Concepts

### Version Sets vs Revisions

| Feature | Version Sets | Revisions |
|---------|-------------|-----------|
| **Purpose** | Breaking changes | Non-breaking changes |
| **Visibility** | Multiple versions live simultaneously | Only one revision is current |
| **URL** | Different URLs (v1, v2, etc.) | Same URL |
| **Use Case** | Major API changes | Bug fixes, minor updates |
| **Example** | v1 and v2 both accessible | Deploy v1.1, test, then make current |

### Version Sets (What You Need!)

A **Version Set** is a logical grouping of API versions:

```
Weather API (Version Set)
├── v1 - https://api.example.com/weather/v1
├── v2 - https://api.example.com/weather/v2
└── v3 - https://api.example.com/weather/v3
```

All three versions are live and accessible simultaneously.

## Versioning Schemes

APIM supports three versioning schemes:

### 1. Path-Based (Recommended)

```
https://api.example.com/v1/products
https://api.example.com/v2/products
```

**Pros:** Clear, visible, cacheable, SEO-friendly
**Cons:** URL changes between versions

### 2. Query String

```
https://api.example.com/products?api-version=1
https://api.example.com/products?api-version=2
```

**Pros:** Same base URL
**Cons:** Not as clear, caching issues

### 3. Header-Based

```
GET /products HTTP/1.1
Api-Version: 1.0

GET /products HTTP/1.1
Api-Version: 2.0
```

**Pros:** Clean URLs, flexible
**Cons:** Less discoverable, harder to test

## The Solution: Complete Examples

I'll create complete examples showing:
1. C# API with proper versioning
2. Generating separate OpenAPI specs per version
3. APIM Version Sets in Bicep
4. Importing to APIM correctly

Let's get this sorted! 🚀

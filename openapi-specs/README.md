# OpenAPI Specifications

This directory stores OpenAPI (Swagger) specifications for APIs that will be imported into Azure API Management.

## 📁 Directory Structure

```
openapi-specs/
├── README.md                    ← You are here
├── products-api-v1.json         ← Example: Products API version 1
├── products-api-v2.json         ← Example: Products API version 2
├── orders-api-v1.json           ← Example: Orders API version 1
│
├── dev/                         ← Development environment specs
│   ├── products-api-v1.json
│   └── products-api-v2.json
│
├── staging/                     ← Staging environment specs
│   ├── products-api-v1.json
│   └── products-api-v2.json
│
└── prod/                        ← Production environment specs
    ├── products-api-v1.json
    └── products-api-v2.json
```

## 🎯 Purpose

These OpenAPI specifications are used to:

1. **Import APIs into APIM** - Define API structure, operations, and schemas
2. **Version Control** - Track changes to API contracts over time
3. **Documentation** - Generate developer portal documentation
4. **Decouple Deployment** - Deploy infrastructure without requiring running APIs

## 🔄 How Specs Are Generated

### Automatic Generation (Recommended)

OpenAPI specs are automatically generated during the build process:

```bash
# Generate specs from running API
cd api/VersionedAPI
dotnet run -- --export-openapi --output ../../openapi-specs

# This creates:
# - versioned-api-v1.json
# - versioned-api-v2.json
# - versioned-api-v3.json (if v3 exists)
```

### CI/CD Pipeline Generation

In Azure DevOps or GitHub Actions, specs are generated and uploaded automatically:

```yaml
# Azure DevOps
- script: |
    cd api/VersionedAPI
    dotnet run -- --export-openapi --output $(Build.ArtifactStagingDirectory)/openapi-specs

# GitHub Actions
- run: |
    cd api/VersionedAPI
    dotnet run -- --export-openapi --output ${{ github.workspace }}/artifacts/openapi-specs
```

## 📝 Naming Conventions

### Standard Naming Pattern
```
{api-name}-{version}.json

Examples:
- products-api-v1.json
- products-api-v2.json
- orders-api-v1.json
- customers-api-v1.json
```

### Alternative: Organized by API
```
products-api/
  v1.json
  v2.json
  v3.json

orders-api/
  v1.json
  v2.json
```

### Environment-Specific
```
dev/products-api-v1.json
staging/products-api-v1.json
prod/products-api-v1.json
```

## ✅ Validation

Always validate OpenAPI specs before committing:

```bash
# Install validator
npm install -g @apidevtools/swagger-cli

# Validate single file
swagger-cli validate products-api-v1.json

# Validate all specs
for spec in *.json; do
  echo "Validating $spec..."
  swagger-cli validate "$spec"
done
```

## 📤 Upload to Azure Blob Storage

For production deployments, upload specs to blob storage:

```bash
# Upload single file
az storage blob upload \
  --account-name apimspecs123 \
  --container-name openapi-specs \
  --name products-api-v1.json \
  --file products-api-v1.json \
  --auth-mode login \
  --overwrite

# Upload entire directory
az storage blob upload-batch \
  --account-name apimspecs123 \
  --destination openapi-specs \
  --source . \
  --pattern "*.json" \
  --auth-mode login \
  --overwrite
```

## 🔧 Using Specs in Bicep

### Option 1: From Blob Storage (Recommended)
```bicep
module api 'modules/api-from-storage.bicep' = {
  params: {
    storageAccountName: 'apimspecs123'
    openApiSpecBlobName: 'products-api-v1.json'
    sasToken: sasToken
  }
}
```

### Option 2: From Repository (Small Specs)
```bicep
module api 'modules/api-from-file.bicep' = {
  params: {
    openApiSpecPath: '../openapi-specs/products-api-v1.json'
  }
}
```

## 📋 Checklist for New Specs

Before committing a new OpenAPI spec:

- [ ] Spec is valid JSON
- [ ] Validated with swagger-cli
- [ ] Follows naming convention
- [ ] Includes proper version in info.version
- [ ] Includes description and contact information
- [ ] All paths use correct base URL
- [ ] Security definitions included (if needed)
- [ ] Examples provided for complex schemas
- [ ] No hardcoded servers (use variables)

## 🔒 Security Considerations

### Do NOT Include in Specs:
- ❌ API keys or secrets
- ❌ Production server URLs (use variables)
- ❌ Internal network addresses
- ❌ Authentication tokens
- ❌ Database connection strings

### Do Include:
- ✅ Security scheme definitions (OAuth2, API Key, etc.)
- ✅ Required authentication flows
- ✅ Scope definitions
- ✅ Authorization requirements per operation

## 🏷️ Version Control Best Practices

### Git Workflow
```bash
# 1. Generate new specs
dotnet run -- --export-openapi

# 2. Validate changes
swagger-cli validate products-api-v2.json

# 3. Review diff
git diff products-api-v2.json

# 4. Commit with descriptive message
git add openapi-specs/
git commit -m "feat: Add search endpoint to Products API v2"
```

### Semantic Versioning
- **v1, v2, v3** - Major versions (breaking changes)
- **Revisions** - Non-breaking changes (don't create new spec)

## 📊 Tracking Changes

Keep a CHANGELOG.md for each API version:

```markdown
# Products API Changelog

## v2.0 (2024-01-15)
- Added search endpoint
- Added filtering capabilities
- Added stock management

## v1.0 (2023-06-01)
- Initial release
- Basic CRUD operations
```

## 🛠️ Troubleshooting

### Spec Not Found During Import
- Verify file exists in storage account
- Check SAS token is valid and has read permissions
- Ensure container name matches Bicep parameter
- Verify blob name (case sensitive!)

### Invalid OpenAPI Spec
```bash
# Run validation
swagger-cli validate products-api-v1.json

# Common issues:
# - Missing required fields (info, paths, openapi version)
# - Invalid JSON syntax
# - Incorrect schema references
# - Missing operationId
```

### Large Spec Files
- Use blob storage instead of inline Bicep
- Consider splitting into multiple smaller APIs
- Remove unnecessary examples
- Compress repeated schemas with $ref

## 🔗 Related Documentation

- [API Import Strategies](../docs/api-import-strategies.md)
- [API Versioning Guidelines](../docs/api-versioning-guidelines.md)
- [Bicep Module: api-from-storage](../bicep/modules/api-from-storage.bicep)
- [Bicep Module: api-from-file](../bicep/modules/api-from-file.bicep)
- [CI/CD Pipeline Examples](../.azuredevops/pipelines/)

## 📞 Need Help?

- See [API Import Strategies](../docs/api-import-strategies.md) for detailed guidance
- Check [Troubleshooting Guide](../docs/concepts/versioning-troubleshooting.md)
- Review example pipeline: `.azuredevops/pipelines/deploy-apis-to-apim.yml`

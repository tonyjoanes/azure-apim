# API Import Strategies for Azure APIM

## The Problem with Endpoint-Based Import

The common approach of importing from a running swagger endpoint doesn't scale:

```bicep
// ❌ DOESN'T SCALE - Creates circular dependencies
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    format: 'openapi+json-link'
    value: 'https://myapi.azurewebsites.net/swagger/v1/swagger.json'  // Requires API running
  }
}
```

**Problems**:
- ❌ API must be deployed and running before infrastructure
- ❌ Circular dependency: APIM needs API URL, but API needs APIM URL
- ❌ Doesn't work with versioned APIs (multiple swagger endpoints)
- ❌ Can't deploy infrastructure without running services
- ❌ Brittle - fails if API is down during deployment

## Recommended Strategies

### Strategy 1: File-Based Import with Blob Storage ⭐ RECOMMENDED

Store OpenAPI specs in Azure Blob Storage and import during deployment.

**Architecture**:
```
Build Pipeline → Generate OpenAPI specs → Upload to Blob Storage
Infrastructure Pipeline → Import from Blob Storage → Deploy to APIM
```

**Pros**:
- ✅ No circular dependencies
- ✅ Works offline (no running API needed)
- ✅ Scales to unlimited versions
- ✅ Version controlled via storage versioning
- ✅ Fast and reliable
- ✅ Supports private storage with SAS tokens

**Cons**:
- Requires blob storage account
- Two-step deployment process

**Example**:
```bicep
// Import from blob storage with SAS token
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    format: 'openapi+json-link'
    value: 'https://mystorageaccount.blob.core.windows.net/openapi-specs/products-api-v1.json?${sasToken}'
  }
}
```

---

### Strategy 2: File-Based Import with Inline Content

Store OpenAPI specs in your repository and embed them in Bicep.

**Architecture**:
```
Repository → openapi-specs/ folder → Bicep reads files → Deploy to APIM
```

**Pros**:
- ✅ No external dependencies
- ✅ Version controlled in Git
- ✅ Works offline
- ✅ Simple to understand
- ✅ Perfect for smaller APIs

**Cons**:
- Bicep file size limits (4MB for template)
- Harder to manage large specs

**Example**:
```bicep
// Read OpenAPI spec from file
var openApiSpec = loadTextContent('../openapi-specs/products-api-v1.json')

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  properties: {
    format: 'openapi+json'
    value: openApiSpec  // Inline content
  }
}
```

---

### Strategy 3: Generate and Import in CI/CD Pipeline

Generate OpenAPI specs during build and upload directly to APIM via Azure CLI/PowerShell.

**Architecture**:
```
Build → Generate OpenAPI → Store as artifact
Deploy → Use az apim api import command
```

**Pros**:
- ✅ Full automation
- ✅ No manual file management
- ✅ Works with any spec size
- ✅ Can validate before import

**Cons**:
- Requires pipeline scripting
- More complex than declarative Bicep

**Example (Azure DevOps)**:
```yaml
- task: AzureCLI@2
  displayName: 'Import API to APIM'
  inputs:
    azureSubscription: '$(azureSubscription)'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az apim api import \
        --resource-group $(resourceGroup) \
        --service-name $(apimName) \
        --api-id products-api-v1 \
        --path products \
        --specification-path $(Build.ArtifactStagingDirectory)/openapi/products-api-v1.json \
        --specification-format OpenApiJson \
        --api-version v1 \
        --api-version-set-id products-version-set
```

---

### Strategy 4: Repository-Based with Git Integration

Store specs in a separate repository and use Git submodules or artifact feeds.

**Architecture**:
```
OpenAPI Specs Repo → Git submodule → Infrastructure Repo → Deploy
```

**Pros**:
- ✅ Separation of concerns
- ✅ Reusable specs across projects
- ✅ Independent versioning

**Cons**:
- Complex repository management
- Requires Git submodule knowledge

---

## Recommended Approach for Versioned APIs

### Multi-Version Deployment Pattern

```
Repository Structure:
/openapi-specs/
  /products-api/
    v1.json
    v2.json
    v3.json
  /orders-api/
    v1.json
    v2.json

Build Process:
1. dotnet build → Generate OpenAPI specs
2. Export specs to /openapi-specs/
3. Upload to blob storage OR commit to repo

Deployment Process:
1. Create Version Set
2. Import v1 spec → Link to Version Set
3. Import v2 spec → Link to Version Set
4. Import v3 spec → Link to Version Set
```

---

## Step-by-Step: Blob Storage Approach (RECOMMENDED)

### 1. Create Storage Account for OpenAPI Specs

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'apimspecs${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false  // Use SAS tokens for security
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'openapi-specs'
  properties: {
    publicAccess: 'None'
  }
}
```

### 2. Generate OpenAPI Specs During Build

See the updated `Program.cs` example in the next section.

### 3. Upload Specs to Blob Storage (CI/CD)

```bash
# Azure CLI
az storage blob upload \
  --account-name apimspecs123 \
  --container-name openapi-specs \
  --name products-api-v1.json \
  --file ./artifacts/openapi/products-api-v1.json \
  --auth-mode login

# Generate SAS token for read access (24 hour expiry)
END_DATE=$(date -u -d "24 hours" '+%Y-%m-%dT%H:%MZ')
SAS_TOKEN=$(az storage blob generate-sas \
  --account-name apimspecs123 \
  --container-name openapi-specs \
  --name products-api-v1.json \
  --permissions r \
  --expiry $END_DATE \
  --auth-mode login \
  --output tsv)
```

### 4. Import from Blob Storage

```bicep
param sasToken string  // Pass from pipeline or Key Vault
param storageAccountName string

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: 'products-api-v1'
  properties: {
    displayName: 'Products API v1'
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id
    path: 'products'
    protocols: ['https']
    format: 'openapi+json-link'
    value: 'https://${storageAccountName}.blob.core.windows.net/openapi-specs/products-api-v1.json?${sasToken}'
    subscriptionRequired: true
  }
}
```

---

## Comparison Matrix

| Strategy | Scales Well | No Dependencies | Git Versioned | Offline Deploy | Complexity |
|----------|-------------|-----------------|---------------|----------------|------------|
| **Blob Storage** | ✅ Excellent | ⚠️ Needs Storage | ✅ Via Storage | ✅ Yes | Medium |
| **Inline Content** | ⚠️ 4MB Limit | ✅ None | ✅ Yes | ✅ Yes | Low |
| **CLI in Pipeline** | ✅ Excellent | ⚠️ Needs Pipeline | ✅ Yes | ❌ No | High |
| **Git Submodules** | ✅ Excellent | ⚠️ Needs Repo | ✅ Yes | ✅ Yes | High |
| **Swagger Endpoint** | ❌ Poor | ❌ Needs Running API | ❌ No | ❌ No | Low |

---

## Best Practices

### 1. Naming Convention for Spec Files
```
{api-name}-{version}.json
products-api-v1.json
products-api-v2.json
orders-api-v1.json
```

### 2. Organize by Environment
```
/openapi-specs/
  /dev/
    products-api-v1.json
  /staging/
    products-api-v1.json
  /prod/
    products-api-v1.json
```

### 3. Automate Spec Generation
- Generate during build, not manually
- Validate specs before upload
- Version specs with API code

### 4. Security
- Use private blob storage with SAS tokens
- Rotate SAS tokens regularly
- Use managed identities where possible
- Never commit SAS tokens to Git

### 5. Validation
```bash
# Validate OpenAPI spec before upload
npx @apidevtools/swagger-cli validate products-api-v1.json

# Or use Azure CLI
az apim api validate-specification \
  --resource-group myResourceGroup \
  --service-name myAPIM \
  --specification-path products-api-v1.json
```

---

## Migration Path

### Current State: Endpoint-Based
```bicep
value: 'https://myapi.azurewebsites.net/swagger/v1/swagger.json'
```

### Step 1: Add Export to Build
Generate spec files during build (see next section)

### Step 2: Parallel Import
Import from both endpoint AND file temporarily

### Step 3: Switch to File-Based
Remove endpoint dependency, use blob storage

### Step 4: Full Automation
Integrate with CI/CD for automatic deployment

---

## Decision Tree

```
Do you have multiple API versions?
├─ Yes → Use Blob Storage or CLI Pipeline approach
└─ No
    ├─ Is your OpenAPI spec < 100KB?
    │   └─ Yes → Use Inline Content (loadTextContent)
    └─ No → Use Blob Storage
```

---

## Next Steps

1. Choose your import strategy (recommended: Blob Storage)
2. Update build process to generate OpenAPI specs
3. Create storage infrastructure (if using blob storage)
4. Update Bicep modules to import from chosen source
5. Test with one API version
6. Scale to all APIs and versions
7. Automate in CI/CD pipeline

See the following files for implementation:
- `/api/VersionedAPI/Program.cs` - OpenAPI export configuration
- `/bicep/modules/api-from-storage.bicep` - Blob storage import
- `/bicep/modules/api-from-file.bicep` - Inline file import
- `/.azuredevops/pipelines/deploy-apis.yml` - CI/CD example

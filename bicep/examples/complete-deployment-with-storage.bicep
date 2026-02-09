// ============================================================================
// Complete APIM Deployment with OpenAPI Specs from Storage
// ============================================================================
// This example demonstrates the complete, production-ready pattern for
// deploying versioned APIs to APIM using OpenAPI specs from blob storage.
//
// Deployment Steps:
// 1. Create OpenAPI storage account
// 2. Create APIM service
// 3. Create Version Set for Products API
// 4. Import v1 API from blob storage
// 5. Import v2 API from blob storage
// 6. Create product and subscriptions

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('APIM service name (must be globally unique)')
param apimServiceName string

@description('APIM SKU tier')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param apimSku string = 'Developer'

@description('Storage account name for OpenAPI specs')
param storageAccountName string

@description('SAS token for accessing blob storage (without leading ?)')
@secure()
param sasToken string

@description('Publisher email for APIM')
param publisherEmail string = 'admin@example.com'

@description('Publisher name for APIM')
param publisherName string = 'API Team'

// ============================================================================
// 1. Create Storage Account for OpenAPI Specs
// ============================================================================
module openApiStorage '../modules/openapi-storage.bicep' = {
  name: 'deploy-openapi-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    sku: 'Standard_LRS'
    enableVersioning: true
    softDeleteRetentionDays: 30
    tags: {
      purpose: 'APIM OpenAPI Specifications'
      environment: 'production'
    }
  }
}

// ============================================================================
// 2. Create APIM Service
// ============================================================================
module apim '../modules/apim.bicep' = {
  name: 'deploy-apim-service'
  params: {
    apimName: apimServiceName
    location: location
    sku: apimSku
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// ============================================================================
// 3. Create Version Set for Products API
// ============================================================================
module productsVersionSet '../modules/api-version-set.bicep' = {
  name: 'deploy-products-version-set'
  params: {
    apimServiceName: apim.outputs.apimName
    versionSetName: 'products-version-set'
    versionSetDisplayName: 'Products API'
    versionSetDescription: 'Versioned Products API with v1 and v2'
    versioningScheme: 'Segment'  // URL path versioning
  }
  dependsOn: [
    apim
  ]
}

// ============================================================================
// 4. Import Products API v1 from Blob Storage
// ============================================================================
module productsApiV1 '../modules/api-from-storage.bicep' = {
  name: 'deploy-products-api-v1'
  params: {
    apimServiceName: apim.outputs.apimName
    apiName: 'products-api-v1'
    apiDisplayName: 'Products API v1'
    apiDescription: 'Products API version 1 - Basic CRUD operations'
    apiVersion: 'v1'
    apiVersionSetId: productsVersionSet.outputs.versionSetId
    apiPath: 'products'
    isCurrent: false  // v2 is current
    storageAccountName: storageAccountName
    storageContainerName: 'openapi-specs'
    openApiSpecBlobName: 'versioned-api-v1.json'
    sasToken: sasToken
    subscriptionRequired: true
    serviceUrl: ''  // Add backend URL if needed
  }
  dependsOn: [
    productsVersionSet
    openApiStorage
  ]
}

// ============================================================================
// 5. Import Products API v2 from Blob Storage
// ============================================================================
module productsApiV2 '../modules/api-from-storage.bicep' = {
  name: 'deploy-products-api-v2'
  params: {
    apimServiceName: apim.outputs.apimName
    apiName: 'products-api-v2'
    apiDisplayName: 'Products API v2'
    apiDescription: 'Products API version 2 - Enhanced with search and filtering'
    apiVersion: 'v2'
    apiVersionSetId: productsVersionSet.outputs.versionSetId
    apiPath: 'products'
    isCurrent: true  // Mark v2 as recommended version
    storageAccountName: storageAccountName
    storageContainerName: 'openapi-specs'
    openApiSpecBlobName: 'versioned-api-v2.json'
    sasToken: sasToken
    subscriptionRequired: true
    serviceUrl: ''  // Add backend URL if needed
  }
  dependsOn: [
    productsVersionSet
    openApiStorage
  ]
}

// ============================================================================
// 6. Create Product (Groups APIs Together)
// ============================================================================
module productsProduct '../modules/product.bicep' = {
  name: 'deploy-products-product'
  params: {
    apimServiceName: apim.outputs.apimName
    productName: 'products-api-product'
    productDisplayName: 'Products API'
    productDescription: 'Access to all versions of the Products API'
    approvalRequired: false
    subscriptionRequired: true
    state: 'published'
    // Associate both API versions with the product
    apiIds: [
      productsApiV1.outputs.apiId
      productsApiV2.outputs.apiId
    ]
  }
  dependsOn: [
    productsApiV1
    productsApiV2
  ]
}

// ============================================================================
// Outputs
// ============================================================================
output apimServiceName string = apim.outputs.apimName
output apimGatewayUrl string = apim.outputs.gatewayUrl
output apimPortalUrl string = apim.outputs.portalUrl

output storageAccountName string = openApiStorage.outputs.storageAccountName
output storageSpecsContainerUrl string = '${openApiStorage.outputs.blobEndpoint}${openApiStorage.outputs.specsContainerName}'

output productsVersionSetId string = productsVersionSet.outputs.versionSetId
output productsApiV1Id string = productsApiV1.outputs.apiId
output productsApiV2Id string = productsApiV2.outputs.apiId
output productsProductId string = productsProduct.outputs.productId

// Gateway URLs for testing
output productsV1Url string = '${apim.outputs.gatewayUrl}/products/v1/products'
output productsV2Url string = '${apim.outputs.gatewayUrl}/products/v2/products'

/* ============================================================================
   DEPLOYMENT COMMAND
   ============================================================================

   # 1. Generate SAS token (valid for 2 hours)
   END_DATE=$(date -u -d "2 hours" '+%Y-%m-%dT%H:%MZ')
   SAS_TOKEN=$(az storage container generate-sas \
     --account-name apimspecs123 \
     --name openapi-specs \
     --permissions r \
     --expiry $END_DATE \
     --auth-mode login \
     --output tsv)

   # 2. Deploy infrastructure
   az deployment group create \
     --resource-group rg-apim-learning \
     --template-file complete-deployment-with-storage.bicep \
     --parameters \
       apimServiceName=apim-learning-001 \
       storageAccountName=apimspecs123 \
       sasToken="$SAS_TOKEN" \
       publisherEmail=admin@example.com \
       publisherName="API Team"

   # 3. Verify deployment
   az apim api list \
     --resource-group rg-apim-learning \
     --service-name apim-learning-001 \
     --query "[].{Name:name, Version:apiVersion, Path:path}" \
     --output table

   ============================================================================ */

/* ============================================================================
   EXPECTED RESULT IN APIM PORTAL
   ============================================================================

   When you browse to the APIM Developer Portal, you should see:

   Products API
   ├── v1 (Deprecated - uses basic model)
   │   ├── GET /products/v1/products
   │   ├── GET /products/v1/products/{id}
   │   ├── POST /products/v1/products
   │   ├── PUT /products/v1/products/{id}
   │   └── DELETE /products/v1/products/{id}
   │
   └── v2 (Current - recommended)
       ├── GET /products/v2/products
       ├── GET /products/v2/products/{id}
       ├── GET /products/v2/products/search
       ├── POST /products/v2/products
       ├── PUT /products/v2/products/{id}
       ├── PATCH /products/v2/products/{id}/stock
       └── DELETE /products/v2/products/{id}

   ============================================================================ */

/* ============================================================================
   WORKFLOW SUMMARY
   ============================================================================

   BUILD PHASE:
   1. Developer writes C# API code
   2. Build pipeline compiles code
   3. dotnet run --export-openapi generates specs
   4. Specs uploaded to blob storage

   DEPLOYMENT PHASE:
   5. Generate SAS token for storage access
   6. Bicep creates APIM service
   7. Bicep creates Version Set
   8. Bicep imports v1 from blob → links to Version Set
   9. Bicep imports v2 from blob → links to Version Set
   10. Both versions visible in APIM!

   BENEFITS:
   ✅ No circular dependency (API doesn't need to be running)
   ✅ Scales to unlimited versions
   ✅ Infrastructure and app deployment decoupled
   ✅ OpenAPI specs version controlled in storage
   ✅ Secure (private storage with SAS tokens)
   ✅ Fast deployment (parallel imports)

   ============================================================================ */

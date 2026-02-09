// ============================================================================
// API Import from Azure Blob Storage
// ============================================================================
// This module imports an API into APIM using an OpenAPI spec stored in
// Azure Blob Storage. This is the RECOMMENDED approach for production.
//
// USE WHEN:
// - OpenAPI spec is > 100KB (or approaching template size limits)
// - Multiple environments (dev/staging/prod)
// - Production deployments
// - CI/CD pipeline deployments
//
// ADVANTAGES:
// - No Bicep template size limits
// - Scales to any number of APIs/versions
// - Supports private storage with SAS tokens
// - Decouples API specs from infrastructure code
// - Can version specs independently

@description('The name of the existing APIM service')
param apimServiceName string

@description('The name of the API to create')
param apiName string

@description('Display name for the API')
param apiDisplayName string

@description('Description of the API')
param apiDescription string = ''

@description('API version (e.g., v1, v2, v3)')
param apiVersion string

@description('The ID of the version set this API belongs to')
param apiVersionSetId string

@description('API path (without version prefix)')
param apiPath string

@description('Whether this is the current/recommended version')
param isCurrent bool = false

@description('Storage account name where OpenAPI spec is stored')
param storageAccountName string

@description('Container name in storage account')
param storageContainerName string = 'openapi-specs'

@description('Blob name (filename) of the OpenAPI spec')
param openApiSpecBlobName string

@description('SAS token for accessing the blob (without leading ?)')
@secure()
param sasToken string = ''

@description('Use managed identity instead of SAS token')
param useManagedIdentity bool = false

@description('Require subscription key for API access')
param subscriptionRequired bool = true

@description('Protocols supported by the API')
param protocols array = ['https']

@description('Service URL (backend)')
param serviceUrl string = ''

// ============================================================================
// Construct blob URL
// ============================================================================
var blobUrl = 'https://${storageAccountName}.blob.core.windows.net/${storageContainerName}/${openApiSpecBlobName}'
var blobUrlWithSas = !empty(sasToken) ? '${blobUrl}?${sasToken}' : blobUrl

// ============================================================================
// Get reference to existing APIM service
// ============================================================================
resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

// ============================================================================
// Create API with OpenAPI spec from blob storage
// ============================================================================
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: apiName
  properties: {
    displayName: apiDisplayName
    description: apiDescription
    apiVersion: apiVersion
    apiVersionSetId: apiVersionSetId
    path: apiPath
    protocols: protocols
    subscriptionRequired: subscriptionRequired
    isCurrent: isCurrent
    serviceUrl: !empty(serviceUrl) ? serviceUrl : null

    // Import from blob storage URL
    format: 'openapi+json-link'
    value: blobUrlWithSas
  }
}

// ============================================================================
// Outputs
// ============================================================================
output apiId string = api.id
output apiName string = api.name
output apiPath string = api.properties.path
output specUrl string = blobUrl

/* ============================================================================
   USAGE EXAMPLE 1: With SAS Token (Recommended for CI/CD)
   ============================================================================

   // Generate SAS token in pipeline and pass as parameter
   module apiV1 'modules/api-from-storage.bicep' = {
     name: 'deploy-products-api-v1'
     params: {
       apimServiceName: apimService.name
       apiName: 'products-api-v1'
       apiDisplayName: 'Products API v1'
       apiVersion: 'v1'
       apiVersionSetId: versionSet.id
       apiPath: 'products'
       storageAccountName: 'apimspecs123'
       storageContainerName: 'openapi-specs'
       openApiSpecBlobName: 'products-api-v1.json'
       sasToken: sasTokenSecret  // Pass from Key Vault or pipeline variable
       serviceUrl: 'https://backend-api.azurewebsites.net'
     }
   }

   ============================================================================ */

/* ============================================================================
   USAGE EXAMPLE 2: Deploy All Versions from Storage
   ============================================================================

   param sasToken string

   module versionSet 'modules/api-version-set.bicep' = {
     name: 'deploy-products-version-set'
     params: {
       apimServiceName: apimService.name
       versionSetName: 'products-version-set'
       versionSetDisplayName: 'Products API'
       versioningScheme: 'Segment'
     }
   }

   // Deploy v1
   module apiV1 'modules/api-from-storage.bicep' = {
     name: 'deploy-products-api-v1'
     params: {
       apimServiceName: apimService.name
       apiName: 'products-api-v1'
       apiDisplayName: 'Products API v1'
       apiVersion: 'v1'
       apiVersionSetId: versionSet.outputs.versionSetId
       apiPath: 'products'
       storageAccountName: 'apimspecs123'
       openApiSpecBlobName: 'products-api-v1.json'
       sasToken: sasToken
       isCurrent: false
     }
   }

   // Deploy v2
   module apiV2 'modules/api-from-storage.bicep' = {
     name: 'deploy-products-api-v2'
     params: {
       apimServiceName: apimService.name
       apiName: 'products-api-v2'
       apiDisplayName: 'Products API v2'
       apiVersion: 'v2'
       apiVersionSetId: versionSet.outputs.versionSetId
       apiPath: 'products'
       storageAccountName: 'apimspecs123'
       openApiSpecBlobName: 'products-api-v2.json'
       sasToken: sasToken
       isCurrent: true
     }
   }

   ============================================================================ */

/* ============================================================================
   CI/CD PIPELINE INTEGRATION
   ============================================================================

   STEP 1: Generate OpenAPI Specs
   ───────────────────────────────
   - script: |
       cd api/VersionedAPI
       dotnet run -- --export-openapi --output $(Build.ArtifactStagingDirectory)/openapi-specs
     displayName: 'Export OpenAPI Specs'

   STEP 2: Upload to Blob Storage
   ───────────────────────────────
   - task: AzureCLI@2
     displayName: 'Upload OpenAPI Specs to Storage'
     inputs:
       azureSubscription: '$(azureSubscription)'
       scriptType: 'bash'
       scriptLocation: 'inlineScript'
       inlineScript: |
         az storage blob upload-batch \
           --account-name apimspecs123 \
           --destination openapi-specs \
           --source $(Build.ArtifactStagingDirectory)/openapi-specs \
           --auth-mode login \
           --overwrite

   STEP 3: Generate SAS Token
   ───────────────────────────
   - task: AzureCLI@2
     displayName: 'Generate SAS Token'
     inputs:
       azureSubscription: '$(azureSubscription)'
       scriptType: 'bash'
       scriptLocation: 'inlineScript'
       inlineScript: |
         END_DATE=$(date -u -d "2 hours" '+%Y-%m-%dT%H:%MZ')
         SAS_TOKEN=$(az storage container generate-sas \
           --account-name apimspecs123 \
           --name openapi-specs \
           --permissions r \
           --expiry $END_DATE \
           --auth-mode login \
           --output tsv)
         echo "##vso[task.setvariable variable=SasToken;issecret=true]$SAS_TOKEN"

   STEP 4: Deploy Infrastructure
   ───────────────────────────────
   - task: AzureResourceManagerTemplateDeployment@3
     displayName: 'Deploy APIM APIs'
     inputs:
       deploymentScope: 'Resource Group'
       azureResourceManagerConnection: '$(azureSubscription)'
       resourceGroupName: '$(resourceGroup)'
       location: '$(location)'
       templateLocation: 'Linked artifact'
       csmFile: 'bicep/main.bicep'
       overrideParameters: '-sasToken $(SasToken)'

   ============================================================================ */

/* ============================================================================
   SECURITY BEST PRACTICES
   ============================================================================

   1. Use Private Storage:
      - Set allowBlobPublicAccess: false on storage account
      - Use SAS tokens with minimal permissions (read only)
      - Set short expiry times (1-2 hours for deployments)

   2. SAS Token Management:
      - NEVER commit SAS tokens to Git
      - Generate in pipeline, not manually
      - Store in Azure Key Vault for reuse
      - Use account SAS or container SAS, not blob SAS

   3. Managed Identity (Alternative to SAS):
      - Grant APIM managed identity "Storage Blob Data Reader" role
      - Set useManagedIdentity: true in Bicep
      - No SAS token needed
      - More secure for production

   4. Network Security:
      - Use private endpoints for storage account
      - Restrict storage firewall to APIM subnet
      - Enable storage analytics logging

   ============================================================================ */

/* ============================================================================
   STORAGE ACCOUNT SETUP
   ============================================================================

   // Create storage account for OpenAPI specs
   resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
     name: 'apimspecs${uniqueString(resourceGroup().id)}'
     location: location
     sku: {
       name: 'Standard_LRS'
     }
     kind: 'StorageV2'
     properties: {
       accessTier: 'Hot'
       allowBlobPublicAccess: false
       minimumTlsVersion: 'TLS1_2'
       supportsHttpsTrafficOnly: true
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

   ============================================================================ */

// ============================================================================
// OpenAPI Specs Storage Account
// ============================================================================
// This module creates a dedicated Azure Storage Account for storing OpenAPI
// specifications that will be imported into APIM.
//
// Benefits:
// - Centralized storage for all API specifications
// - Version history via blob versioning
// - Secure access via SAS tokens or managed identity
// - No dependency on running APIs during deployment

@description('Storage account name (must be globally unique, 3-24 chars, lowercase/numbers only)')
param storageAccountName string

@description('Azure region for the storage account')
param location string = resourceGroup().location

@description('Storage account SKU')
@allowed([
  'Standard_LRS'   // Locally redundant (cheapest)
  'Standard_GRS'   // Geo-redundant
  'Standard_RAGRS' // Read-access geo-redundant
])
param sku string = 'Standard_LRS'

@description('Enable blob versioning for OpenAPI spec history')
param enableVersioning bool = true

@description('Days to retain deleted specs (soft delete)')
param softDeleteRetentionDays int = 7

@description('Tags for the storage account')
param tags object = {
  purpose: 'APIM OpenAPI Specifications'
  managedBy: 'Bicep'
}

// ============================================================================
// Storage Account
// ============================================================================
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false  // Security: no public access
    minimumTlsVersion: 'TLS1_2'   // Security: enforce TLS 1.2+
    supportsHttpsTrafficOnly: true // Security: HTTPS only
    allowSharedKeyAccess: true     // Allow SAS tokens

    // Enable blob versioning for history
    isVersioningEnabled: enableVersioning
  }
}

// ============================================================================
// Blob Service Configuration
// ============================================================================
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    // Soft delete for blobs
    deleteRetentionPolicy: {
      enabled: true
      days: softDeleteRetentionDays
    }

    // Soft delete for containers
    containerDeleteRetentionPolicy: {
      enabled: true
      days: softDeleteRetentionDays
    }

    // Enable versioning at service level
    isVersioningEnabled: enableVersioning
  }
}

// ============================================================================
// Container for OpenAPI Specs
// ============================================================================
resource specsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'openapi-specs'
  properties: {
    publicAccess: 'None' // Private container
    metadata: {
      description: 'OpenAPI specifications for APIM import'
    }
  }
}

// ============================================================================
// Optional: Containers for Different Environments
// ============================================================================
resource devContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'openapi-specs-dev'
  properties: {
    publicAccess: 'None'
    metadata: {
      environment: 'Development'
    }
  }
}

resource stagingContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'openapi-specs-staging'
  properties: {
    publicAccess: 'None'
    metadata: {
      environment: 'Staging'
    }
  }
}

resource prodContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'openapi-specs-prod'
  properties: {
    publicAccess: 'None'
    metadata: {
      environment: 'Production'
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output specsContainerName string = specsContainer.name

// Container URLs for different environments
output devContainerUrl string = '${storageAccount.properties.primaryEndpoints.blob}${devContainer.name}'
output stagingContainerUrl string = '${storageAccount.properties.primaryEndpoints.blob}${stagingContainer.name}'
output prodContainerUrl string = '${storageAccount.properties.primaryEndpoints.blob}${prodContainer.name}'

/* ============================================================================
   USAGE EXAMPLE
   ============================================================================

   module openApiStorage 'modules/openapi-storage.bicep' = {
     name: 'deploy-openapi-storage'
     params: {
       storageAccountName: 'apimspecs${uniqueString(resourceGroup().id)}'
       location: location
       sku: 'Standard_LRS'
       enableVersioning: true
       softDeleteRetentionDays: 30
       tags: {
         environment: 'production'
         project: 'apim-learning'
       }
     }
   }

   output storageAccountName string = openApiStorage.outputs.storageAccountName

   ============================================================================ */

/* ============================================================================
   MANAGED IDENTITY ACCESS CONFIGURATION
   ============================================================================

   If you want to use APIM's managed identity instead of SAS tokens:

   // 1. Enable managed identity on APIM
   resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
     name: apimServiceName
   }

   // 2. Grant APIM the "Storage Blob Data Reader" role
   resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
     name: guid(storageAccount.id, apimService.id, 'StorageBlobDataReader')
     scope: storageAccount
     properties: {
       roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
       principalId: apimService.identity.principalId
       principalType: 'ServicePrincipal'
     }
   }

   ============================================================================ */

/* ============================================================================
   FOLDER STRUCTURE IN STORAGE
   ============================================================================

   Recommended blob naming convention:

   openapi-specs/
     products-api-v1.json
     products-api-v2.json
     products-api-v3.json
     orders-api-v1.json
     orders-api-v2.json
     customers-api-v1.json

   OR organize by API:

   openapi-specs/
     products-api/
       v1.json
       v2.json
       v3.json
     orders-api/
       v1.json
       v2.json

   OR organize by environment:

   openapi-specs-dev/
     products-api-v1.json
     products-api-v2.json

   openapi-specs-staging/
     products-api-v1.json
     products-api-v2.json

   openapi-specs-prod/
     products-api-v1.json
     products-api-v2.json

   ============================================================================ */

/* ============================================================================
   UPLOAD SPECS TO STORAGE (Azure CLI)
   ============================================================================

   # Upload a single file
   az storage blob upload \
     --account-name apimspecs123 \
     --container-name openapi-specs \
     --name products-api-v1.json \
     --file ./openapi-specs/products-api-v1.json \
     --auth-mode login \
     --overwrite

   # Upload entire directory
   az storage blob upload-batch \
     --account-name apimspecs123 \
     --destination openapi-specs \
     --source ./openapi-specs \
     --auth-mode login \
     --overwrite

   # Generate SAS token for read access (24 hours)
   END_DATE=$(date -u -d "24 hours" '+%Y-%m-%dT%H:%MZ')
   SAS_TOKEN=$(az storage container generate-sas \
     --account-name apimspecs123 \
     --name openapi-specs \
     --permissions r \
     --expiry $END_DATE \
     --auth-mode login \
     --output tsv)

   echo "SAS Token: $SAS_TOKEN"

   ============================================================================ */

/* ============================================================================
   SECURITY CHECKLIST
   ============================================================================

   ✅ allowBlobPublicAccess: false
   ✅ minimumTlsVersion: TLS1_2
   ✅ supportsHttpsTrafficOnly: true
   ✅ publicAccess: None on all containers
   ✅ Soft delete enabled
   ✅ Versioning enabled
   ✅ Use SAS tokens with minimal permissions
   ✅ Short SAS token expiry (hours, not days)
   ✅ Or use managed identity (better)
   ✅ Enable Azure Monitor diagnostic logs
   ✅ Consider private endpoints for VNet integration

   ============================================================================ */

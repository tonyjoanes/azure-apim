// ============================================================================
// API Import from File (Inline Content)
// ============================================================================
// This module imports an API into APIM using an OpenAPI spec file stored
// in the repository. The file content is embedded inline in the Bicep template.
//
// USE WHEN:
// - OpenAPI spec is < 100KB
// - Spec is version controlled in Git
// - No external dependencies desired
// - Simple deployment scenarios
//
// LIMITATIONS:
// - Bicep template has 4MB size limit
// - File must be accessible at deployment time

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

@description('Relative path to the OpenAPI spec file from this Bicep file')
param openApiSpecPath string

@description('Require subscription key for API access')
param subscriptionRequired bool = true

@description('Protocols supported by the API')
param protocols array = ['https']

@description('Service URL (backend)')
param serviceUrl string = ''

// ============================================================================
// Load OpenAPI spec from file
// ============================================================================
// The loadTextContent function reads the file at deployment time
var openApiSpecContent = loadTextContent(openApiSpecPath)

// ============================================================================
// Get reference to existing APIM service
// ============================================================================
resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

// ============================================================================
// Create API with inline OpenAPI spec
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

    // Import OpenAPI spec directly from file content
    format: 'openapi+json'
    value: openApiSpecContent
  }
}

// ============================================================================
// Outputs
// ============================================================================
output apiId string = api.id
output apiName string = api.name
output apiPath string = api.properties.path

/* ============================================================================
   USAGE EXAMPLE
   ============================================================================

   module apiV1 'modules/api-from-file.bicep' = {
     name: 'deploy-products-api-v1'
     params: {
       apimServiceName: apimService.name
       apiName: 'products-api-v1'
       apiDisplayName: 'Products API v1'
       apiDescription: 'Products API version 1'
       apiVersion: 'v1'
       apiVersionSetId: versionSet.id
       apiPath: 'products'
       isCurrent: false
       openApiSpecPath: '../openapi-specs/products-api-v1.json'
       subscriptionRequired: true
       serviceUrl: 'https://backend-api.azurewebsites.net'
     }
   }

   module apiV2 'modules/api-from-file.bicep' = {
     name: 'deploy-products-api-v2'
     params: {
       apimServiceName: apimService.name
       apiName: 'products-api-v2'
       apiDisplayName: 'Products API v2'
       apiDescription: 'Products API version 2'
       apiVersion: 'v2'
       apiVersionSetId: versionSet.id
       apiPath: 'products'
       isCurrent: true  // Mark v2 as current
       openApiSpecPath: '../openapi-specs/products-api-v2.json'
       subscriptionRequired: true
       serviceUrl: 'https://backend-api.azurewebsites.net'
     }
   }

   ============================================================================ */

/* ============================================================================
   FOLDER STRUCTURE
   ============================================================================

   /bicep/
     /modules/
       api-from-file.bicep         ← This file
     /examples/
       deploy-versioned-api.bicep  ← Uses this module
   /openapi-specs/
     products-api-v1.json
     products-api-v2.json
     orders-api-v1.json

   The openApiSpecPath is relative to the Bicep file using this module.
   If called from /bicep/examples/deploy.bicep, the path would be:
   '../../openapi-specs/products-api-v1.json'

   ============================================================================ */

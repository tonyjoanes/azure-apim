// Example: Deploy versioned APIs to APIM with Version Sets
// This demonstrates the CORRECT way to set up API versioning in APIM

@description('The name of the API Management service')
param apimServiceName string

@description('Backend API URL for v1')
param backendUrlV1 string

@description('Backend API URL for v2')
param backendUrlV2 string

// Step 1: Create the Version Set
// This groups v1 and v2 as versions of the same API
module productVersionSet '../modules/api-version-set.bicep' = {
  name: 'products-version-set'
  params: {
    apimServiceName: apimServiceName
    versionSetName: 'products-versions'
    versionSetDisplayName: 'Products API'
    versionSetDescription: 'Products API with multiple versions'
    versioningScheme: 'Segment'  // URL path versioning: /v1/products, /v2/products
  }
}

// Step 2: Import Version 1
// Import the OpenAPI spec for v1 and associate with version set
module productsApiV1 '../modules/api-versioned.bicep' = {
  name: 'products-api-v1'
  params: {
    apimServiceName: apimServiceName
    apiName: 'products-api-v1'
    apiDisplayName: 'Products API v1'
    apiDescription: 'Products API version 1 - Basic functionality'
    apiVersion: 'v1'
    apiPath: 'products'  // Will become /v1/products due to version set
    serviceUrl: backendUrlV1
    versionSetId: productVersionSet.outputs.versionSetId
    isCurrent: false  // v2 is the current version
    subscriptionRequired: true
    // OpenAPI spec for v1 would be loaded here
    // openApiSpec: loadTextContent('../../specs/products-v1.json')
  }
  dependsOn: [
    productVersionSet
  ]
}

// Step 3: Import Version 2
// Import the OpenAPI spec for v2 and associate with the SAME version set
module productsApiV2 '../modules/api-versioned.bicep' = {
  name: 'products-api-v2'
  params: {
    apimServiceName: apimServiceName
    apiName: 'products-api-v2'
    apiDisplayName: 'Products API v2'
    apiDescription: 'Products API version 2 - Enhanced with search and filtering'
    apiVersion: 'v2'
    apiPath: 'products'  // Same path, different version
    serviceUrl: backendUrlV2
    versionSetId: productVersionSet.outputs.versionSetId
    isCurrent: true  // This is the current/recommended version
    subscriptionRequired: true
    // OpenAPI spec for v2 would be loaded here
    // openApiSpec: loadTextContent('../../specs/products-v2.json')
  }
  dependsOn: [
    productVersionSet
  ]
}

// Optional: Add both versions to a product
module productAssociations '../modules/product.bicep' = {
  name: 'product-associations'
  params: {
    apimServiceName: apimServiceName
    productName: 'products-all-versions'
    productDisplayName: 'Products API - All Versions'
    productDescription: 'Access to all versions of the Products API'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
    apiNames: [
      productsApiV1.outputs.apiName
      productsApiV2.outputs.apiName
    ]
  }
  dependsOn: [
    productsApiV1
    productsApiV2
  ]
}

// Outputs
@description('Version Set ID')
output versionSetId string = productVersionSet.outputs.versionSetId

@description('V1 API Name')
output v1ApiName string = productsApiV1.outputs.apiName

@description('V2 API Name')
output v2ApiName string = productsApiV2.outputs.apiName

@description('V1 Gateway URL')
output v1Url string = 'https://${apimServiceName}.azure-api.net/v1/products'

@description('V2 Gateway URL')
output v2Url string = 'https://${apimServiceName}.azure-api.net/v2/products'

# Bicep Templates for Azure APIM

This directory contains Infrastructure as Code (IaC) templates using Bicep for deploying Azure API Management and related resources.

## Structure

```
bicep/
├── main/
│   ├── main.bicep           # Main deployment template
│   ├── main.parameters.json # Parameters file
│   └── README.md           # Deployment instructions
└── modules/
    ├── apim.bicep          # APIM instance module
    ├── api.bicep           # API definition module
    ├── product.bicep       # Product module
    ├── policy.bicep        # Policy module
    ├── backend.bicep       # Backend module
    ├── subscription.bicep  # Subscription module
    └── named-values.bicep  # Named values module
```

## Prerequisites

- Azure CLI installed
- Azure subscription
- Appropriate permissions to create resources

## Quick Deploy

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create resource group
az group create --name rg-apim-demo --location eastus

# Deploy the main template
az deployment group create \
  --resource-group rg-apim-demo \
  --template-file main/main.bicep \
  --parameters main/main.parameters.json
```

## Deployment Steps

1. **Review Parameters**: Update `main/main.parameters.json` with your values
2. **Deploy Infrastructure**: Run deployment command
3. **Verify Deployment**: Check Azure Portal for resources
4. **Configure APIs**: Import API specifications
5. **Set Up Products**: Create products and subscriptions

## Modules Overview

### apim.bicep
Deploys the APIM instance with configurable:
- Service tier (Developer, Basic, Standard, Premium)
- Virtual network integration
- Managed identity
- Custom domain
- Application Insights

### api.bicep
Defines APIs with:
- OpenAPI specification import
- Service URL
- Versioning
- Subscriptions requirement

### product.bicep
Creates products with:
- API associations
- Rate limiting
- Approval requirement
- Visibility settings

### policy.bicep
Configures policies at:
- Global level
- Product level
- API level
- Operation level

### backend.bicep
Defines backend services:
- Backend URL
- Protocol (HTTP/SOAP)
- Credentials
- Circuit breaker settings

### subscription.bicep
Manages subscriptions:
- Product subscriptions
- API subscriptions
- Primary/secondary keys

### named-values.bicep
Stores configuration values:
- API keys
- Connection strings
- Feature flags
- Backend URLs

## Cost Considerations

Different APIM tiers have different pricing:
- **Consumption**: Pay per execution
- **Developer**: For dev/test, no SLA
- **Basic**: Entry production tier
- **Standard**: Mid-range production
- **Premium**: Enterprise with multi-region

See [Azure APIM Pricing](https://azure.microsoft.com/pricing/details/api-management/) for details.

## Best Practices

1. **Use Developer tier** for learning and testing
2. **Enable Managed Identity** for secure authentication
3. **Integrate Application Insights** for monitoring
4. **Use Named Values** for configuration
5. **Store secrets** in Azure Key Vault
6. **Tag resources** for cost management
7. **Use modules** for reusability

## Next Steps

After deployment:
1. Access Developer Portal: `https://{apim-name}.developer.azure-api.net`
2. Access Gateway: `https://{apim-name}.azure-api.net`
3. Import sample APIs
4. Create products
5. Test with .http files

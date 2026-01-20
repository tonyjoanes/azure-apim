# Main Deployment Template

This directory contains the main deployment template for Azure API Management infrastructure.

## Files

- `main.bicep` - Main deployment template
- `main.parameters.json` - Parameters file (update with your values)

## Prerequisites

1. Azure CLI installed
2. Azure subscription
3. Contributor access to the subscription

## Quick Start

### 1. Update Parameters

Edit `main.parameters.json` and update:
- `apimServiceName` - Unique name for your APIM instance
- `publisherEmail` - Your email address
- `publisherName` - Your organization name
- `location` - Azure region (optional, defaults to resource group location)

### 2. Login to Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

### 3. Create Resource Group

```bash
az group create \
  --name rg-apim-learning \
  --location eastus
```

### 4. Validate Template

```bash
az deployment group validate \
  --resource-group rg-apim-learning \
  --template-file main.bicep \
  --parameters main.parameters.json
```

### 5. Deploy

```bash
az deployment group create \
  --resource-group rg-apim-learning \
  --template-file main.bicep \
  --parameters main.parameters.json \
  --name apim-deployment
```

**Note:** APIM deployment can take 30-45 minutes.

### 6. Get Outputs

```bash
az deployment group show \
  --resource-group rg-apim-learning \
  --name apim-deployment \
  --query properties.outputs
```

## What Gets Deployed

This template deploys:

1. **Log Analytics Workspace** - For monitoring and diagnostics
2. **Application Insights** - For telemetry and logging
3. **API Management Instance** - The main APIM service
   - System-assigned managed identity enabled
   - TLS 1.2 enforced
   - HTTP/2 enabled
   - Application Insights integration
4. **Starter Product** - Basic product for testing
5. **Premium Product** - Advanced product with approval required

## Post-Deployment Steps

After deployment completes:

1. **Access Developer Portal**
   - URL: `https://{apim-name}.developer.azure-api.net`
   - Sign in with Azure AD

2. **Access Gateway**
   - URL: `https://{apim-name}.azure-api.net`

3. **Access Azure Portal**
   - Navigate to your APIM instance
   - Configure APIs, Products, and Policies

4. **Import Sample APIs**
   - Use the API modules to deploy sample APIs
   - Import OpenAPI specifications

5. **Create Subscriptions**
   - Create subscriptions for testing
   - Get subscription keys

## Cleanup

To delete all resources:

```bash
az group delete --name rg-apim-learning --yes --no-wait
```

## Cost Estimation

**Developer Tier:**
- ~$50-60/month
- No SLA
- For development/testing only

**Basic Tier:**
- ~$200/month
- 99.95% SLA
- Production-ready

See [APIM Pricing](https://azure.microsoft.com/pricing/details/api-management/) for details.

## Troubleshooting

### Deployment Takes Too Long
- APIM deployment typically takes 30-45 minutes
- This is normal behavior

### Name Already Exists
- APIM names must be globally unique
- Try a different name in parameters file

### Insufficient Permissions
- Ensure you have Contributor role on the subscription
- Check RBAC permissions

## Next Steps

1. Import your first API using `../modules/api.bicep`
2. Configure policies using `../modules/policy.bicep`
3. Set up backends using `../modules/backend.bicep`
4. Create named values for configuration
5. Test with the sample .http files in `/tests`

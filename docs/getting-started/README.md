# Getting Started with Azure API Management

This guide will help you get started with Azure API Management (APIM) from scratch.

## What You'll Learn

- What Azure APIM is and why it's useful
- Key components and concepts
- How to deploy your first APIM instance
- How to import and test your first API

## Prerequisites

Before you begin, ensure you have:

- **Azure Subscription** - [Create a free account](https://azure.microsoft.com/free/)
- **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **.NET 8 SDK** - For sample API project
- **Visual Studio Code** - With REST Client extension
- **Git** - For cloning this repository

## What is Azure API Management?

Azure API Management is a fully managed service that enables you to:

- **Publish APIs** to external, partner, and internal developers
- **Secure APIs** with various authentication methods
- **Transform and protect** backends without modifying code
- **Monitor and analyze** API usage
- **Manage API lifecycle** with versioning and revisions
- **Developer portal** for API documentation and testing

## Key Benefits

1. **Security** - Protect your backend services with authentication, rate limiting, and IP filtering
2. **Analytics** - Gain insights into API usage and performance
3. **Developer Experience** - Provide a self-service portal for developers
4. **Transformation** - Modify requests and responses without changing backend code
5. **Scalability** - Handle traffic spikes with caching and throttling
6. **Multi-cloud** - Works with backends hosted anywhere

## Quick Start

### Step 1: Deploy APIM

```bash
# Clone this repository
git clone <your-repo-url>
cd azure-apim

# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Create resource group
az group create --name rg-apim-learning --location eastus

# Deploy APIM (takes 30-45 minutes)
az deployment group create \
  --resource-group rg-apim-learning \
  --template-file bicep/main/main.bicep \
  --parameters bicep/main/main.parameters.json
```

### Step 2: Access Your APIM Instance

After deployment:

1. **Azure Portal**: Navigate to your APIM instance
2. **Developer Portal**: `https://{apim-name}.developer.azure-api.net`
3. **Gateway URL**: `https://{apim-name}.azure-api.net`

### Step 3: Deploy Sample API

```bash
# Navigate to the API directory
cd api/SampleAPI

# Build and publish (instructions in api/README.md)
dotnet publish -c Release
```

### Step 4: Import API to APIM

```bash
# Use the API module to import
az deployment group create \
  --resource-group rg-apim-learning \
  --template-file bicep/modules/api.bicep \
  --parameters @path/to/api-parameters.json
```

### Step 5: Test Your API

Use the `.http` files in the `/tests` directory to test your API endpoints.

## Understanding the Repository Structure

```
azure-apim/
├── bicep/          # Infrastructure as Code
├── docs/           # This documentation
├── api/            # Sample C# API
├── specs/          # OpenAPI specifications
├── policies/       # Policy examples
├── tests/          # HTTP test files
├── diagrams/       # Architecture diagrams
└── examples/       # Practical scenarios
```

## Learning Path

Follow this recommended order:

1. **Concepts** - Understand APIM components and architecture
2. **Deployment** - Deploy APIM using Bicep
3. **APIs** - Create and manage APIs
4. **Products** - Organize APIs into products
5. **Policies** - Apply transformations and security
6. **Authentication** - Secure your APIs
7. **Testing** - Test APIs with .http files
8. **Monitoring** - Monitor with Application Insights

## Common Terminology

- **Gateway** - The endpoint that receives API requests
- **Developer Portal** - Self-service portal for API consumers
- **API** - A set of operations exposed through the gateway
- **Product** - A collection of one or more APIs
- **Subscription** - Provides access to APIs via subscription keys
- **Policy** - Rules that modify request/response behavior
- **Backend** - The actual service behind the gateway
- **Operation** - An individual API endpoint (e.g., GET /users)

## Next Steps

- [Understand APIM Components](../concepts/components.md)
- [Learn about Service Tiers](../concepts/service-tiers.md)
- [Deploy with Bicep](../../bicep/README.md)
- [Explore Architecture Diagrams](../../diagrams/README.md)

## Getting Help

- [Official Azure APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [APIM Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure APIM Community](https://techcommunity.microsoft.com/t5/azure-paas-blog/bg-p/AzurePaaSBlog)

## Cost Management Tips

- Use **Developer tier** for learning (no SLA, ~$50/month)
- Delete resources when not in use
- Use **Consumption tier** for very low usage scenarios
- Monitor costs in Azure Cost Management

Ready to dive deeper? Start with [APIM Concepts](../concepts/what-is-apim.md)!

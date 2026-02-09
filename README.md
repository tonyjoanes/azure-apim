# Azure API Management (APIM) Learning Resources

A comprehensive guide to learning and implementing Azure API Management, including infrastructure as code, policies, authentication, and practical examples.

## Overview

This repository provides a complete learning path for Azure API Management (APIM), covering everything from basic concepts to advanced configurations. Whether you're new to APIM or looking to deepen your knowledge, you'll find structured resources, working examples, and deployable infrastructure code.

## Repository Structure

```
📁 azure-apim/
├── 📁 bicep/                      # Infrastructure as Code templates
│   ├── 📁 modules/                # Reusable Bicep modules
│   │   ├── api-from-storage.bicep # Import APIs from blob storage ⭐
│   │   ├── api-from-file.bicep    # Import APIs from repository files
│   │   ├── openapi-storage.bicep  # Storage account for OpenAPI specs
│   │   ├── api-version-set.bicep  # APIM Version Sets (critical!)
│   │   └── api-versioned.bicep    # Versioned API deployment
│   └── 📁 examples/               # Complete deployment examples
├── 📁 docs/                       # Documentation
│   ├── 📁 concepts/               # Core concepts
│   ├── 📁 authentication/         # Auth methods
│   ├── 📁 policies/               # Policy guides
│   ├── api-import-strategies.md   # ⭐ NEW: How to import APIs at scale
│   ├── api-versioning-guidelines.md  # Versioning standards
│   └── api-versioning-guidelines-enforcement.md  # Mandatory requirements
├── 📁 api/                        # Sample C# API projects
│   └── VersionedAPI/              # Example versioned API
│       ├── OpenApiExporter.cs     # Export specs to files ⭐
│       └── Program.ExportExample.cs  # Export examples
├── 📁 openapi-specs/              # ⭐ NEW: OpenAPI specifications storage
│   ├── dev/                       # Development environment specs
│   ├── staging/                   # Staging environment specs
│   ├── prod/                      # Production environment specs
│   └── README.md                  # Spec management guide
├── 📁 .azuredevops/pipelines/     # ⭐ NEW: Azure DevOps CI/CD
│   └── deploy-apis-to-apim.yml    # Complete deployment pipeline
├── 📁 .github/workflows/          # ⭐ NEW: GitHub Actions
│   └── deploy-apis-to-apim.yml    # Complete deployment workflow
├── 📁 policies/                   # Policy examples
│   ├── 📁 examples/
│   └── 📁 fragments/
├── 📁 tests/                      # .http test files
├── 📁 diagrams/                   # Mermaid diagrams
└── 📁 examples/                   # Practical scenarios
```

## Quick Start

1. **[Getting Started Guide](docs/getting-started/README.md)** - Begin here for prerequisites and initial setup
2. **[APIM Architecture](diagrams/README.md)** - Understand APIM components and architecture
3. **[Deploy APIM with Bicep](bicep/README.md)** - Deploy your first APIM instance
4. **[Sample API](api/README.md)** - Deploy the sample C# API
5. **[Testing APIs](tests/README.md)** - Test endpoints using .http files

## Learning Path

### 1. Core Concepts
- [What is Azure APIM?](docs/concepts/what-is-apim.md)
- [APIM Components](docs/concepts/components.md)
- [Service Tiers](docs/concepts/service-tiers.md)
- [Architecture Overview](docs/concepts/architecture.md)

### 2. Infrastructure Setup
- [Bicep Templates](bicep/README.md)
- [Deploying APIM](docs/getting-started/deployment.md)
- [Network Configuration](docs/concepts/networking.md)
- [Azure Key Vault Integration](docs/concepts/key-vault.md)

### 3. API Management Basics
- [APIs](docs/concepts/apis.md)
- [Operations](docs/concepts/operations.md)
- [Backends](docs/concepts/backends.md)
- [API Specifications](specs/README.md)

### 4. Products & Subscriptions
- [Understanding Products](docs/products/what-are-products.md)
- [Creating Products](docs/products/creating-products.md)
- [Subscription Keys](docs/products/subscription-keys.md)
- [API Keys Explained](docs/authentication/api-keys.md)

### 5. Policies
- [Policy Overview](docs/policies/overview.md)
- [Policy Structure](docs/policies/structure.md)
- [Common Policies](docs/policies/common-policies.md)
- [Policy Examples](policies/examples/README.md)
- [Policy Fragments](policies/fragments/README.md)
- [Transformation Policies](docs/policies/transformation.md)
- [Security Policies](docs/policies/security.md)

### 6. Authentication & Authorization
- [Authentication Overview](docs/authentication/overview.md)
- [Subscription Keys](docs/authentication/subscription-keys.md)
- [OAuth 2.0](docs/authentication/oauth2.md)
- [JWT Validation](docs/authentication/jwt-validation.md)
- [Client Certificates](docs/authentication/client-certificates.md)
- [Managed Identity](docs/authentication/managed-identity.md)

### 7. Testing & Development
- [Testing with .http Files](tests/README.md)
- [Mock Responses](docs/testing/mock-responses.md)
- [Debugging Policies](docs/testing/debugging.md)
- [Developer Portal](docs/concepts/developer-portal.md)

### 8. API Versioning (CRITICAL for APIM)
- [Complete Versioning Guide](docs/concepts/versioning-complete-guide.md) - How to make all versions visible in APIM
- [API Versioning Guidelines](docs/api-versioning-guidelines.md) - Mandatory standards for API versioning
- [Enforcement Standards](docs/api-versioning-guidelines-enforcement.md) - PR checklist and compliance
- [Versioning Troubleshooting](docs/concepts/versioning-troubleshooting.md) - Fix common issues
- [Placeholder Explanation](docs/concepts/versioning-placeholders-explained.md) - Understanding {version:apiVersion}
- [Meeting Plan](docs/meeting-plan-versioning.md) - Present versioning to your team
- [Executive Summary](docs/versioning-standards-summary.md) - Business case for leadership

### 9. API Import Strategies (NEW - Scalable Deployment)
- **[API Import Strategies](docs/api-import-strategies.md)** - **START HERE** for scalable APIM deployments
- [OpenAPI Storage Module](bicep/modules/openapi-storage.bicep) - Blob storage for specs
- [API from Storage Module](bicep/modules/api-from-storage.bicep) - Import from blob storage
- [API from File Module](bicep/modules/api-from-file.bicep) - Import from repository files
- [Complete Deployment Example](bicep/examples/complete-deployment-with-storage.bicep) - Full workflow
- [Azure DevOps Pipeline](.azuredevops/pipelines/deploy-apis-to-apim.yml) - CI/CD automation
- [GitHub Actions Workflow](.github/workflows/deploy-apis-to-apim.yml) - CI/CD automation
- [OpenAPI Specs Folder](openapi-specs/README.md) - Organizing specifications

### 10. Advanced Topics
- [Rate Limiting & Quotas](docs/policies/rate-limiting.md)
- [Caching Strategies](docs/policies/caching.md)
- [CORS Configuration](docs/policies/cors.md)
- [Monitoring & Logging](docs/monitoring/overview.md)
- [Application Insights Integration](docs/monitoring/app-insights.md)

## Diagrams

Visual representations to help understand APIM concepts:

- [APIM Architecture](diagrams/architecture.mmd)
- [Request Flow](diagrams/request-flow.mmd)
- [Policy Execution Order](diagrams/policy-execution.mmd)
- [Authentication Flows](diagrams/auth-flows.mmd)
- [Product & Subscription Model](diagrams/products-subscriptions.mmd)

## Practical Examples

- [Simple GET/POST API](examples/simple-api/)
- [API with Authentication](examples/auth-api/)
- [Rate Limited API](examples/rate-limited-api/)
- [Transformation Example](examples/transformation/)
- [Caching Example](examples/caching/)
- [Mock API](examples/mock-api/)

## Sample API Project

A complete C# Web API project located in the [api/](api/) directory that you can deploy and use with APIM.

## Prerequisites

- Azure subscription
- Azure CLI installed
- .NET 8 SDK (for sample API)
- Visual Studio Code or Visual Studio
- REST Client extension (for .http files)
- Git

## Contributing

This is a learning repository. Feel free to expand and customize it for your own learning journey.

## Resources

- [Official Azure APIM Documentation](https://learn.microsoft.com/en-us/azure/api-management/)
- [APIM Policy Reference](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## License

This repository is for educational purposes.

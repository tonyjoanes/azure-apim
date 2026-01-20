# Azure API Management (APIM) Learning Resources

A comprehensive guide to learning and implementing Azure API Management, including infrastructure as code, policies, authentication, and practical examples.

## Overview

This repository provides a complete learning path for Azure API Management (APIM), covering everything from basic concepts to advanced configurations. Whether you're new to APIM or looking to deepen your knowledge, you'll find structured resources, working examples, and deployable infrastructure code.

## Repository Structure

```
📁 azure-apim/
├── 📁 bicep/              # Infrastructure as Code templates
│   ├── 📁 modules/        # Reusable Bicep modules
│   └── 📁 main/          # Main deployment templates
├── 📁 docs/               # Documentation
│   ├── 📁 getting-started/
│   ├── 📁 concepts/
│   ├── 📁 authentication/
│   ├── 📁 policies/
│   ├── 📁 products/
│   ├── 📁 testing/
│   └── 📁 monitoring/
├── 📁 api/                # Sample C# API project
├── 📁 specs/              # OpenAPI specifications
├── 📁 policies/           # Policy examples
│   ├── 📁 examples/
│   └── 📁 fragments/
├── 📁 tests/              # .http test files
├── 📁 diagrams/           # Mermaid diagrams
└── 📁 examples/           # Practical scenarios
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

### 8. Advanced Topics
- [Versioning & Revisions](docs/concepts/versioning.md)
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

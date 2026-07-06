# 🌍 Enterprise Highly Available Multi-Region Web Application on Azure

## Azure Front Door Premium + Application Gateway + App Service + Terraform

> Production-ready Azure infrastructure built using Terraform to deploy a secure, scalable, and highly available multi-region web application leveraging Azure Front Door Premium, Application Gateway, Private Link, and App Service.

![Azure](https://img.shields.io/badge/Microsoft-Azure-0078D4?logo=microsoftazure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Enterprise-success)
![High Availability](https://img.shields.io/badge/High%20Availability-Active--Standby-blue)
![License](https://img.shields.io/badge/License-MIT-green)

---

# 📸 Solution Architecture

<img width="1280" height="698" alt="image" src="https://github.com/user-attachments/assets/d711b16a-c1a0-4ff9-a1b3-072073a65fc0" />


---

## Table of Contents

- [Overview](#overview)
- [Business Scenario](#business-scenario)
- [Why this Architecture?](#why-this-architecture)
- [Architecture Principles](#architecture-principles)
- [Solution Architecture](#solution-architecture)
- [Key Features](#key-features)
- [Azure Services Used](#azure-services-used)
- [High Availability Strategy](#high-availability-strategy)
- [Security Design](#security-design)
- [Terraform Structure](#terraform-structure)
- [Deployment Guide](#deployment-guide)
- [Outputs](#outputs)
- [Routing & Failover](#routing--failover)
- [Validation](#validation)
- [Troubleshooting](#troubleshooting)
- [Cost Considerations](#cost-considerations)
- [Future Enhancements](#future-enhancements)
- [Learning Outcomes](#learning-outcomes)
- [Lessons Learned](#lessons-learned)
- [Repository Statistics](#repository-statistics)
- [Who is this Project For?](#who-is-this-project-for)
- [Cleanup](#cleanup)
- [Azure Well-Architected Framework](#azure-well-architected-framework)
- [Author](#author)

---

# 📖 Overview

This repository provisions a production-ready, enterprise-grade Azure ingress architecture using Terraform.

The deployment consists of:

- Azure Front Door Premium
- Azure Application Gateway Standard_v2
- Linux App Service
- Private Endpoints
- Private DNS
- Virtual Networks
- Network Security Groups

The architecture follows an **Active-Standby** regional deployment model.

Primary Region

- Central India

Standby Region

- South India

Traffic is automatically routed through Azure Front Door, which continuously monitors backend health and redirects traffic to the standby region during outages.

---

# 🎯 Business Scenario

A global organization hosts a customer-facing web application serving users across multiple regions.

The solution must provide:

- High availability
- Regional failover
- Secure private connectivity
- Simplified operations
- Infrastructure as Code
- Production-ready architecture

This project demonstrates how Azure Front Door Premium, Application Gateway, App Service, and Private Link can be combined into a secure and resilient architecture following Microsoft Azure Well-Architected Framework principles.

---

# 🤔 Why this Architecture?

Compared with exposing an Application Gateway directly to the Internet, this design provides:

- Global traffic routing
- Automatic regional failover
- Lower latency
- Better resiliency
- Simplified disaster recovery
- Centralized ingress
- Secure backend communication
- Future-ready architecture for WAF, CDN, and Zero Trust

---

# 🏛 Architecture Principles

This solution is designed around the following principles:

- Reliability
- Security
- Scalability
- Operational Excellence
- Infrastructure as Code
- Modularity
- Maintainability
- Disaster Recovery

---

# 🌐 Solution Architecture

Traffic Flow

```
Client
    │
    ▼
Azure Front Door Premium
    │
    ├──────────────┐
    ▼              ▼
Application      Application
Gateway          Gateway
(Central)        (South)
    │              │
    ▼              ▼
Linux App       Linux App
Service         Service
    │              │
    ▼              ▼
Private Endpoint
        │
        ▼
Private DNS
```

---

# ✨ Key Features

- Enterprise-grade Azure architecture
- Active-Standby deployment
- Global traffic routing
- Automatic failover
- Infrastructure as Code
- Modular Terraform design
- Secure private connectivity
- Private DNS integration
- Production-ready deployment
- Azure networking best practices

---

# ☁ Azure Services Used

| Azure Service | Purpose |
|---------------|----------|
| Azure Front Door Premium | Global entry point |
| Application Gateway | Regional Layer-7 Load Balancer |
| Linux App Service | Application hosting |
| Virtual Network | Network isolation |
| Private Endpoint | Secure backend access |
| Private DNS | Private name resolution |
| NSG | Network Security |
| Terraform | Infrastructure as Code |

---

# 🌍 High Availability Strategy

The architecture provides regional resilience using Azure Front Door Premium.

- Central India acts as the primary region.
- South India acts as the disaster recovery region.
- Azure Front Door continuously performs health probes.
- Automatic failover occurs if the primary region becomes unavailable.
- No manual intervention is required.

---

# 🔒 Security Design

The solution follows a defense-in-depth approach.

Implemented security controls include:

- Azure Front Door as the public entry point
- Application Gateway for regional ingress
- Private Endpoints for App Services
- Private DNS integration
- NSG rules restricting subnet traffic
- Backend isolation
- Foundation for Zero Trust adoption

---

# 📂 Terraform Structure

```
environments/
    prod/

modules/
    resource-group/
    network/
    app-service-plan/
    app-service/
    private-dns/
    private-endpoint/
    app-gateway/
    frontdoor/
```

---

# 🚀 Deployment Guide

## Prerequisites

- Terraform >= 1.5
- Azure CLI
- Azure Subscription
- Contributor permissions

## Deploy

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

Estimated deployment time:

| Component | Time |
|-----------|------|
| App Gateway | 10–15 min |
| Front Door | 20–30 min |
| App Service | 3–5 min |
| Total | 20–30 min |

---

# 📤 Outputs

Terraform returns:

- Front Door URL
- Active Region
- Standby Region
- Origin Hostnames
- Resource Group

---

# 🔄 Routing & Failover

Azure Front Door configuration:

- Primary Origin Priority = 1
- Secondary Origin Priority = 2

Health probes continuously monitor backend availability.

If the primary region becomes unavailable, traffic is automatically redirected to the standby region.

---

# ✅ Validation

```powershell
terraform state list

terraform output
```

```powershell
Invoke-WebRequest -Uri "<frontdoor_url>"
```

---

# 🛠 Troubleshooting

Includes guidance for:

- NSG issues
- Front Door 404
- Front Door 502/503
- Private Endpoint DNS
- Terraform state lock
- Configuration drift
- Failover validation
- Long deployment times

---

# 💰 Cost Considerations

Primary cost drivers:

- Azure Front Door Premium
- Application Gateway Standard_v2
- Linux App Service
- Private Endpoints
- Public IP

This architecture prioritizes reliability and enterprise resilience over minimum infrastructure cost.

---

# 🚀 Future Enhancements

- HTTPS end-to-end
- Azure Key Vault
- Managed Identity
- GitHub Actions
- Azure DevOps
- Azure Monitor
- Log Analytics
- Azure Policy
- Active-Active architecture
- WAF custom rules
- Bicep implementation
- AKS deployment

---

# 📚 Learning Outcomes

This project demonstrates practical implementation of:

- Azure Front Door
- Application Gateway
- Private Link
- Private DNS
- Azure Networking
- Disaster Recovery
- High Availability
- Infrastructure as Code
- Terraform Modules

---

# 💡 Lessons Learned

During implementation several real-world Azure networking challenges were encountered:

- Application Gateway NSG validation
- Front Door health probe configuration
- Private Endpoint DNS resolution
- Terraform state management
- Backend routing
- Regional failover testing

Resolving these issues helped shape a more resilient and production-ready architecture.

---

# 📊 Repository Statistics

| Metric | Value |
|----------|--------|
| Regions | 2 |
| Availability Model | Active-Standby |
| Azure Services | 8 |
| Terraform Modules | 8 |
| Private Endpoints | 2 |
| Virtual Networks | 2 |

---

# 👥 Who is this Project For?

- Cloud Engineers
- Azure Architects
- DevOps Engineers
- Platform Engineers
- Infrastructure Engineers
- Students preparing for AZ-700
- Engineers learning Terraform
- Anyone interested in Azure enterprise networking

---

# 🧹 Cleanup

```powershell
terraform destroy -auto-approve
```

---

# 🏛 Azure Well-Architected Framework

This solution aligns with Microsoft Azure Well-Architected Framework:

- ✅ Reliability
- ✅ Security
- ✅ Operational Excellence
- ✅ Performance Efficiency
- ✅ Cost Optimization

---

# 👨‍💻 Author

**Prandip Barooah**

Cloud Infrastructure Architect | Azure Networking SME | AI Automation Builder

- 💼 LinkedIn: https://linkedin.com/in/prandip-barooah23
- 💻 GitHub: https://github.com/Prandip23

If you found this repository useful, consider giving it a ⭐.

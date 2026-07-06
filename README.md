# Enterprise Highly Available Multi-Region Web Application on Azure

## Azure Front Door + Application Gateway + App Service + Terraform

> Production-ready Azure infrastructure built with Terraform using Azure Front Door, Application Gateway, and App Service to deliver secure, scalable, and highly available web applications.

![Azure](https://img.shields.io/badge/Azure-Cloud-blue)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple)
![Architecture](https://img.shields.io/badge/Enterprise-Architecture-green)

## Overview

This repository provisions a two-region Azure web application ingress stack with active-standby traffic behavior:

- Active region: `Central India`
- Standby region: `South India`
- Edge: Azure Front Door Premium
- Regional ingress: Azure Application Gateway Standard_v2 (one per region)
- App tier: Linux App Service (one per region)
- Private connectivity: Private Endpoints + Private DNS (`privatelink.azurewebsites.net`)

The solution is designed so Front Door prefers the Central India origin (priority 1) and fails over to South India (priority 2).

## Deployed Topology

Traffic path:

`Client -> Azure Front Door -> Regional App Gateway -> Regional App Service`

Regional layout:

- Central India (active):
	- `vnet-cin`
	- `appgw-subnet` (`10.10.1.0/24`)
	- `private-endpoint-subnet` (`10.10.2.0/24`)
	- `appgw-cin-active`
	- `app-cin-active-tf`
- South India (standby):
	- `vnet-sin`
	- `appgw-subnet` (`10.20.1.0/24`)
	- `private-endpoint-subnet` (`10.20.2.0/24`)
	- `appgw-sin-standby`
	- `app-sin-standby-tf`

## Terraform Structure

- Environment root: `environments/prod`
- Reusable modules: `modules/*`

Implemented modules:

- `resource-group`
- `network`
- `app-service-plan`
- `app-service`
- `private-dns`
- `private-endpoint`
- `app-gateway`
- `frontdoor`

## Prerequisites

- Terraform `>= 1.5.0`
- Azure CLI authenticated with permissions to create networking, App Service, and Front Door resources
- Azure subscription with sufficient quotas in `centralindia` and `southindia`

## Configuration

Primary configuration file:

- `environments/prod/terraform.tfvars`

Required value:

- `subscription_id`

Key defaults in `environments/prod/variables.tf`:

- `resource_group_name = "AFD-AppGw-AppService-TF"`
- `location_primary = "Central India"`
- `location_secondary = "South India"`

## Deploy

From `environments/prod`:

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

## Outputs

After apply, Terraform returns:

- `resource_group_name`
- `active_region`
- `standby_region`
- `active_origin`
- `standby_origin`
- `frontdoor_url`

## Routing and Failover

- Front Door route: `default-route`
- Front Door forwarding protocol: `HttpOnly`
- Front Door origin priorities:
	- Central India App Gateway: priority `1` (active)
	- South India App Gateway: priority `2` (standby)

## Security and Network Notes

- App Services have `public_network_access_enabled = false`
- Private Endpoints are created for both App Services
- Private DNS zone is linked to both VNets
- App Gateway subnet NSG rules include:
	- `Allow-GatewayManager-65200-65535`
	- `Allow-AzureFrontDoor-Backend-Http`

## Validation Commands

Use these to inspect the deployment state:

```powershell
terraform state list
terraform output
```

Quick endpoint checks:

```powershell
Invoke-WebRequest -Uri "<frontdoor_url>" -Method Get
Invoke-WebRequest -Uri "http://<active_origin>" -Method Get
Invoke-WebRequest -Uri "http://<standby_origin>" -Method Get
```

## Troubleshooting

### 1. App Gateway Create Fails (NSG Block)

Symptom:

- Terraform apply fails with `ApplicationGatewaySubnetInboundTrafficBlockedByNetworkSecurityGroup`.

Checks:

- Confirm NSG rules exist on both App Gateway subnet NSGs:
	- `Allow-GatewayManager-65200-65535`
	- `Allow-AzureFrontDoor-Backend-Http`

Fix:

- Re-apply from `environments/prod`:

```powershell
terraform apply -auto-approve
```

### 2. Front Door Returns 404

Symptom:

- `frontdoor_url` returns HTTP 404.

Checks:

- Front Door route points to expected origin hostnames (`active_origin`, `standby_origin`).
- App Gateway listener exists on HTTP port 80.
- App Gateway backend health probe path (`/`) returns 200-399.
- App content is actually deployed on both App Services.

Fix:

- Re-check outputs and origins:

```powershell
terraform output
Invoke-WebRequest -Uri "http://<active_origin>" -Method Get
Invoke-WebRequest -Uri "http://<standby_origin>" -Method Get
```

### 3. Front Door Returns 502/503

Symptom:

- Front Door endpoint is reachable but returns 502/503.

Checks:

- App Gateway backend pool resolves and probe is healthy.
- NSG allows Front Door backend traffic to App Gateway subnet on ports 80/443.
- App Service app responds at `/`.

Fix:

- Validate App Gateway origin endpoints first, then Front Door.

### 4. Private Endpoint / DNS Resolution Issues

Symptom:

- App Gateway cannot reliably reach private app backend.

Checks:

- Private Endpoints exist for both apps.
- Private DNS zone `privatelink.azurewebsites.net` exists and is linked to both VNets.
- DNS zone group is attached on each private endpoint.

Fix:

- Re-run apply and verify resources in state:

```powershell
terraform state list
terraform apply -auto-approve
```

### 5. Terraform State File Locked

Symptom:

- Error: state file is locked or cannot be read.

Checks:

- Ensure no other Terraform process is running in another terminal.

Fix:

- Wait for long-running apply to finish.
- If a process is stuck, stop it and rerun `terraform plan`.

### 6. Unexpected Drift on App Service Basic Auth Flags

Symptom:

- Plan repeatedly shows updates for FTP/WebDeploy basic auth flags.

Checks:

- Compare Azure portal runtime settings with Terraform-managed values.

Fix options:

- Keep as-is and allow Terraform to reconcile each apply.
- Or explicitly manage these settings in module code and avoid manual portal edits.

### 7. Region Failover Behavior Not as Expected

Symptom:

- Traffic does not fail over to standby during active-origin disruption.

Checks:

- Front Door origin priorities:
	- active = `1`
	- standby = `2`
- Health probe path and protocol are valid.
- Standby App Gateway and app are healthy.

Fix:

- Validate standby origin directly, then retest Front Door.

### 8. Long Apply Times on App Gateway / Front Door

Symptom:

- Terraform appears slow during create/update.

Notes:

- App Gateway and Front Door operations can take several minutes and this is expected.

Recommendation:

- Allow apply to complete before running another Terraform command.

## Cleanup

From `environments/prod`:

```powershell
terraform destroy -auto-approve
```

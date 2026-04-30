# Burger Builder Application Runbook

## Overview
This runbook provides operational instructions for managing the Burger Builder application hosted on Azure.

## Infrastructure Stack
- **Frontend**: Azure App Service (Linux Node runtime)
- **Backend**: Azure App Service (Linux Java 21 runtime)
- **Database**: Azure SQL Database (Private Endpoint only)
- **Ingress**: Azure Application Gateway (WAF v2)
- **Monitoring**: Azure Monitor, Log Analytics, Application Insights
- **CI/CD**: GitHub Actions
- **IaC**: Terraform
- **Config Management**: Ansible

## Deployment Procedures

### Infrastructure
Changes to infrastructure should be made in `infra/terraform`.
When pushed to the `main` branch, the `Deploy Infrastructure (Terraform)` GitHub Action will automatically plan and apply the changes.

### Applications
Frontend and Backend code changes are automatically built, scanned with SonarQube, and deployed to Azure Web Apps upon merging to the `main` branch via the respective GitHub Actions workflows.

## Monitoring and Alerts

Three primary alerts are configured:
1. **App Gateway Health**: Triggers if backend instances are unhealthy. Check the App Services status if this fires.
2. **CPU Utilization**: Triggers if App Service Plan CPU > 70%. If sustained, consider scaling up the App Service Plan in Terraform.
3. **SQL Database Load**: Triggers if SQL vCore / CPU > 80%. Consider increasing the DTU/vCore limit.

To view detailed logs:
1. Go to **Application Insights** in the Azure Portal.
2. Check the **Failures** or **Performance** tabs to trace slow API calls.

## Troubleshooting

### App Gateway shows "502 Bad Gateway"
1. Verify that the App Services are running.
2. Ensure the custom health probes match the paths (`/` and `/api/ingredients`).
3. Check the App Service logs for startup failures (e.g., missing database connection strings).

### Cannot connect to SQL Database from local machine
This is expected. The database has Public Network Access disabled. It can only be accessed from within the VNet. To run ad-hoc queries, use the Azure Portal's "Query Editor" (if you configure your IP in the firewall or use a jumpbox), or deploy a Bastion host into `snet-ops` and connect from there.

### SonarQube is inaccessible
1. Ensure the Ops VM is running in Azure.
2. Verify the NSG rule allows inbound traffic on port 9000.
3. SSH into the VM and check `docker ps` to see if the `sonarqube` container is healthy.

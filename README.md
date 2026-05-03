# 🍔 Burger Builder — Secure 3-Tier Azure Deployment

A full-stack web application for building and ordering custom burgers, deployed on a production-grade, fully automated 3-tier Azure cloud infrastructure using Terraform, Ansible, and GitHub Actions CI/CD pipelines.

**Live URL:** `http://51.142.251.112` (via Azure Application Gateway WAF v2)

---

## 📐 Architecture Overview

```
                        ┌─────────────────────────────────┐
                        │        Internet (Users)          │
                        └────────────────┬────────────────┘
                                         │ HTTP :80
                        ┌────────────────▼────────────────┐
                        │   Application Gateway (WAF v2)   │
                        │   OWASP 3.2 Rules / Prevention   │
                        └──────────┬──────────────┬────────┘
                                   │              │ /api/*
                     ┌─────────────▼──┐    ┌──────▼──────────┐
                     │  FE VMSS       │    │  BE VMSS         │
                     │  React / pm2   │    │  Spring Boot     │
                     │  :80           │    │  :8080           │
                     │  snet-fe-musa  │    │  snet-be-musa    │
                     └────────────────┘    └──────┬──────────┘
                                                  │ Private Endpoint
                                     ┌────────────▼──────────────┐
                                     │   Azure SQL Database       │
                                     │   (No public access)       │
                                     │   snet-pep                 │
                                     └───────────────────────────┘

           ┌────────────────────────────────────────────┐
           │  SonarQube VM (snet-ops)                   │
           │  • Code quality scanning                   │
           │  • SSH Jumpbox/Bastion for VMSS access     │
           └────────────────────────────────────────────┘
```

### Key Security Design Principles
- **Zero Public Exposure**: FE and BE VMSS have **no public IPs**
- **Private Database**: SQL Server accessible only via Private Endpoint (`10.0.4.x`)
- **WAF Protection**: All traffic filtered by OWASP 3.2 rules
- **SSH via Jumpbox**: Only SonarQube VM accepts SSH from internet; VMSS only accepts SSH from OPS subnet
- **NSG Rules**: Every subnet has strict inbound/outbound rules

---

## 📋 Prerequisites

### 1. Required Tools (Local Machine)
| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | ≥ 2.50 | [docs.microsoft.com/cli/azure/install](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| Terraform | ≥ 1.7.5 | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
| Ansible | ≥ 2.15 | `pip install ansible` |
| Git | Any | [git-scm.com](https://git-scm.com) |
| SSH | Any | Built-in on Mac/Linux |

### 2. Azure Permissions
Your Azure Service Principal must have the **Contributor** role on the subscription.

```bash
# Create Service Principal
az ad sp create-for-rbac \
  --name "burger-builder-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth
```
Save the output — you'll need `clientId`, `clientSecret`, `subscriptionId`, `tenantId`.

### 3. Azure Quotas & Budgets (Important!)
Verify your quota for `standardDASv7Family` vCPUs in your chosen region:
```bash
az vm list-usage --location "UK South" -o table | grep -i "das"
```
> ⚠️ This project uses `Standard_D2ads_v7` VMs (2 vCPUs each × 3 VMs = **6 vCPUs minimum** required).  
> If quota is insufficient, either request an increase or choose another region with free quota.

**Set up Azure Budget alerts** (recommended for cost control):
```bash
# Create a budget alert at 80% of expected monthly cost
az consumption budget create \
  --account-name <billing-account-id> \
  --name "burger-builder-budget" \
  --amount 100 \
  --time-grain Monthly \
  --category Cost \
  --notification-email your-email@example.com \
  --notification-threshold 80
```
Estimated monthly costs (varies by region):
- Application Gateway (WAF v2): ~$200-300/month
- 2x VMSS (Standard_D2ads_v7): ~$150-200/month
- Azure SQL Database: ~$50-100/month
- SonarQube VM: ~$40-60/month
- **Total estimated: ~$440-660/month**

### 4. SSH Key Generation
Generate a **dedicated, passphrase-free** SSH key for this project:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/burger_key -N ""

# View your public key (needed for GitHub Secrets)
cat ~/.ssh/burger_key.pub

# View your private key (needed for GitHub Secrets)
cat ~/.ssh/burger_key
```

### 5. GitHub Repository Secrets
Navigate to your GitHub repo → **Settings → Secrets and variables → Actions** and create all secrets:

| Secret Name | Description | Example |
|---|---|---|
| `AZURE_CLIENT_ID` | Service Principal App ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_CLIENT_SECRET` | Service Principal Password | `your~secret~value` |
| `AZURE_SUBSCRIPTION_ID` | Your Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Your Azure AD Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `SQL_ADMIN_USERNAME` | SQL Server admin login | `group2_sql` |
| `SQL_ADMIN_PASSWORD` | SQL Server admin password (no `'` chars) | `BurgerApp2026!Secure` |
| `VM_SSH_PUBLIC_KEY` | Public SSH key content | `ssh-rsa AAAA...` |
| `VM_SSH_PRIVATE_KEY` | Private SSH key content | `-----BEGIN RSA PRIVATE KEY-----...` |
| `SONAR_HOST_URL` | SonarQube URL (set after step 3) | `http://20.68.203.156:9000` |
| `SONAR_TOKEN_FRONTEND` | SonarQube project token | `sqp_xxxxxxxxxxxx` |
| `SONAR_TOKEN_BACKEND` | SonarQube project token | `sqp_xxxxxxxxxxxx` |

---

## 🏗️ Step 1: Provision Infrastructure (Terraform)

Terraform creates the **entire Azure infrastructure** automatically — VNet, subnets, NSGs, Application Gateway, VMSS clusters, SQL Database, SonarQube VM, and monitoring.

### Automatic via GitHub Actions (Recommended)
Simply push any change to `infra/terraform/**` to the `main` branch, or trigger manually:
1. Go to **Actions → Deploy Infrastructure (Terraform)**
2. Click **Run workflow**

The pipeline will:
1. Create a remote Terraform state storage account in Azure
2. Run `terraform init`, `plan`, and `apply`
3. Output the SonarQube public IP

### Manual Execution
```bash
cd infra/terraform

# Initialize with remote state backend
terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=tfstatemusa2026" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.terraform.tfstate"

# Preview changes
terraform plan \
  -var="sql_admin_username=group2_sql" \
  -var="sql_admin_password=BurgerApp2026!Secure" \
  -var="vm_ssh_public_key=$(cat ~/.ssh/burger_key.pub)"

# Apply
terraform apply -auto-approve \
  -var="sql_admin_username=group2_sql" \
  -var="sql_admin_password=BurgerApp2026!Secure" \
  -var="vm_ssh_public_key=$(cat ~/.ssh/burger_key.pub)"
```

### Terraform Module Structure
```
infra/terraform/
├── main.tf                  # Root: Resource Group, Public IP, module calls
├── variables.tf             # Input variables
├── outputs.tf               # Outputs (SonarQube IP, etc.)
├── terraform.tfvars         # Default variable values (region, CIDR blocks)
└── modules/
    ├── networking/          # VNet, 5 subnets, 4 NSGs
    ├── app_gateway/         # WAF v2 Application Gateway + WAF Policy
    ├── compute/             # VMSS (FE + BE) with autoscaling
    ├── database/            # Azure SQL Server + Private Endpoint + DNS Zone
    ├── sonarqube_vm/        # SonarQube VM with public IP
    └── monitoring/          # Log Analytics + Application Insights + Alerts
```

### Expected Resources Created
| Resource | Name |
|---|---|
| Resource Group | `musa-project2-rg` |
| Virtual Network | `burger-vnet` (10.0.0.0/16) |
| Application Gateway | `burger-appgw` |
| FE VMSS | `burger-vmss-fe-musa` |
| BE VMSS | `burger-vmss-be-musa` |
| SQL Server | `burger-sqlserver` |
| SonarQube VM | `burger-sonar-vm` |

---

## ⚙️ Step 2: Configure Servers (Ansible)

Ansible automatically installs Docker and runs the SonarQube container on the dedicated VM.  
This step is **automatically triggered** at the end of the `infra.yml` GitHub Actions pipeline.

### What Ansible Does
1. Updates system packages
2. Installs Docker and Docker Compose
3. Pulls the official `sonarqube:lts-community` image
4. Starts SonarQube container on port **9000**
5. Configures required kernel parameters (`vm.max_map_count`)

### Manual Execution
```bash
# Get SonarQube IP first
SONAR_IP=$(az network public-ip show \
  -g musa-project2-rg -n burger-sonar-pip \
  --query ipAddress -o tsv)

# Run playbook (uses your SSH private key)
ansible-playbook \
  -i "${SONAR_IP}," \
  -u azureuser \
  --private-key ~/.ssh/burger_key \
  config/ansible/playbooks/sonarqube.yml
```

### Set Up SonarQube Projects (One-time Manual Step)
After Ansible finishes, open `http://<SONAR_IP>:9000` in your browser:

1. Login with `admin` / `admin` → Set a new password
2. **Create Frontend Project**: 
   - Name: `burger-frontend`, Key: `burger-frontend`
   - Generate token → Save as `SONAR_TOKEN_FRONTEND` in GitHub Secrets
3. **Create Backend Project**: 
   - Name: `burger-backend`, Key: `burger-backend`
   - Generate token → Save as `SONAR_TOKEN_BACKEND` in GitHub Secrets
4. Save `http://<SONAR_IP>:9000` as `SONAR_HOST_URL` in GitHub Secrets

---

## 🚀 Step 3: Deploy Applications (GitHub Actions)

### GitHub Actions Workflows
The project includes three GitHub Actions workflows for CI/CD automation:

#### 1. Infrastructure Deployment (`infra.yml`)
- **Triggers**: Push to `main` when files in `infra/terraform/**` change, or manual dispatch
- **Purpose**: Provision Azure infrastructure via Terraform and configure SonarQube via Ansible
- **Steps**:
  1. Azure login with service principal
  2. Create Terraform state storage account
  3. Run `terraform init`, `plan`, and `apply`
  4. Run Ansible playbook to configure SonarQube VM
  5. Output SonarQube public IP

#### 2. Frontend Deployment (`frontend.yml`)

### Frontend Pipeline (`frontend.yml`)
**Triggers:** Push to `main` when files in `frontend/**` change, or manual dispatch.

**Stages:**
1. **Build & Test** — `npm ci`, `npm run test:coverage`, SonarQube scan, `npm run build`, zip artifact
2. **Deploy** — SSH through SonarQube Jumpbox → scp zip to all FE VMSS instances → start with `pm2 serve`

```bash
# Trigger manually
# GitHub → Actions → "Build and Deploy Frontend" → Run workflow
```

#### 3. Backend Deployment (`backend.yml`)
- **Triggers**: Push to `main` when files in `backend/**` change, or manual dispatch
- **Purpose**: Build, test, and deploy Spring Boot backend to BE VMSS
- **Steps**:
  1. Set up Java 21
  2. Build with Maven
  3. Run tests and SonarQube scan
  4. Upload JAR artifact
  5. SSH through SonarQube Jumpbox
  6. Deploy JAR to all BE VMSS instances
  7. Start application with `nohup java -jar`

### Manual Trigger
```bash
# Trigger any workflow manually
# GitHub → Actions → Select workflow → Run workflow
```

### How SSH Deployment Works (ProxyJump)
```
GitHub Actions Runner (Internet)
    │  SSH
    ▼
SonarQube VM (Public IP: 20.68.203.156)    ← Jumpbox / Bastion
    │  SSH through private network
    ▼
FE/BE VMSS (Private IPs: 10.0.2.x / 10.0.3.x)
```

The SSH config used in pipelines:
```
Host sonarqube
  HostName <SONAR_PUBLIC_IP>
  User azureuser
  IdentityFile ~/.ssh/id_rsa

Host 10.0.*
  User azureuser
  ProxyJump sonarqube
  IdentityFile ~/.ssh/id_rsa
```

---

## ✅ Step 4: Validate the Deployment

### Health Check Commands

### 1. Check Application Gateway Backend Health
```bash
az network application-gateway show-backend-health \
  --name burger-appgw \
  --resource-group musa-project2-rg \
  --query "backendAddressPools[].backendHttpSettingsCollection[].servers[].[address,health]" \
  -o table
```
Expected output:
```
Column1    Column2
---------  ---------
10.0.2.4   Healthy    ← Frontend VMSS
10.0.3.5   Healthy    ← Backend VMSS
```

### 2. Check Frontend Server (pm2)
```bash
az vmss run-command invoke \
  -g musa-project2-rg -n burger-vmss-fe-musa \
  --command-id RunShellScript \
  --scripts "sudo pm2 status && ss -tlnp | grep 80" \
  --instance-id 0
```

### 3. Check Backend Server (Java)
```bash
az vmss run-command invoke \
  -g musa-project2-rg -n burger-vmss-be-musa \
  --command-id RunShellScript \
  --scripts "ss -tlnp | grep 8080 && echo 'Java IS running' || echo 'Java NOT running'" \
  --instance-id 1
```

### 4. Test the Application URLs

| Endpoint | Expected Response |
|---|---|
| `http://51.142.251.112` | `200 OK` — Burger Builder UI |
| `http://51.142.251.112/api/ingredients` | `200 OK` — JSON array of ingredients |
| `http://51.142.251.112/api/orders/history` | `200 OK` — JSON array of orders |

### Sample curl / API Tests

**Get all ingredients:**
```bash
curl -s http://51.142.251.112/api/ingredients | python3 -m json.tool
```

**Get ingredients by category:**
```bash
curl -s http://51.142.251.112/api/ingredients/BUNS | python3 -m json.tool
curl -s http://51.142.251.112/api/ingredients/PATTIES | python3 -m json.tool
```

**Add item to cart:**
```bash
curl -X POST http://51.142.251.112/api/cart/items \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "test-session-123",
    "ingredientId": 1,
    "quantity": 1
  }'
```

**Get cart:**
```bash
curl -s http://51.142.251.112/api/cart/test-session-123 | python3 -m json.tool
```

**Create an order:**
```bash
curl -X POST http://51.142.251.112/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "test-session-123",
    "customerName": "John Doe",
    "customerEmail": "john@example.com",
    "customerPhone": "+1234567890",
    "cartItemIds": [1]
  }'
```

**Get order history:**
```bash
curl -s "http://51.142.251.112/api/orders/history?email=john@example.com" | python3 -m json.tool
```

### 6. Postman Collection
Import the following base URL into Postman:  
`http://51.142.251.112`

Key requests to test:
- `GET /api/ingredients` — List all ingredients
- `POST /api/cart/items` — Add to cart (Body: JSON with `sessionId`, `ingredientId`, `quantity`)
- `POST /api/orders` — Place order
- `GET /api/orders/history` — View all orders

---

## 🔧 Troubleshooting Guide

### Bad Gateway (502)
The Application Gateway cannot reach a backend server.
```bash
# Check backend health
az network application-gateway show-backend-health \
  --name burger-appgw --resource-group musa-project2-rg

# Check if Java is running on BE VMSS
az vmss run-command invoke -g musa-project2-rg -n burger-vmss-be-musa \
  --command-id RunShellScript \
  --scripts "ss -tlnp | grep 8080" --instance-id 1
```

### "Failed to load ingredients" (Frontend Error)
The frontend cannot reach the backend API. Verify:
1. Java is running on the BE VMSS (see above)
2. App Gateway backend pool is Healthy
3. Check backend logs: `cat /home/azureuser/app.log`

### SSH Connection Issues
```bash
# Test connection to SonarQube VM
ssh -i ~/.ssh/burger_key -o StrictHostKeyChecking=no azureuser@<SONAR_IP>

# Test ProxyJump to FE VMSS
ssh -i ~/.ssh/burger_key -J azureuser@<SONAR_IP> azureuser@10.0.2.4
```

### Terraform "Resource Already Exists"
This happens when state is out of sync. Clean up and re-run:
```bash
az group delete --name musa-project2-rg --yes --no-wait
```
Wait ~5 minutes, then re-trigger the Terraform pipeline.

---

## 📁 Project Structure

```
.
├── .github/workflows/
│   ├── infra.yml         # Terraform: provision Azure infrastructure + run Ansible
│   ├── frontend.yml      # Build, test, scan, deploy React app to FE VMSS
│   └── backend.yml       # Build, test, scan, deploy Spring Boot to BE VMSS
├── frontend/             # React + TypeScript + Vite application
│   └── src/services/api.ts  # API client (uses relative URL for App Gateway routing)
├── backend/              # Spring Boot REST API (Java 21, Maven)
│   └── src/main/resources/
│       ├── schema.sql    # Database schema (auto-created by Hibernate)
│       └── data.sql      # Seed data for ingredients
├── config/ansible/
│   └── playbooks/sonarqube.yml  # Installs Docker & starts SonarQube
└── infra/terraform/
    ├── main.tf
    ├── terraform.tfvars  # Region: UK South, CIDR blocks
    └── modules/
        ├── networking/   # VNet + 5 subnets + 4 NSGs
        ├── app_gateway/  # WAF v2 + WAF Policy (OWASP 3.2)
        ├── compute/      # VMSS (FE + BE) + autoscaling
        ├── database/     # Azure SQL + Private Endpoint
        ├── sonarqube_vm/ # SonarQube VM (Gen2 Ubuntu 22.04)
        └── monitoring/   # Log Analytics + App Insights + Alerts
```

---

## 📜 License

This project is part of a capstone project (IH DevOps Bootcamp) for educational purposes.

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review GitHub Actions logs in the Actions tab
- Check Azure portal for resource status
- Verify SonarQube scan results at `http://<SONAR_IP>:9000`

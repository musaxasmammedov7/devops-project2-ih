prefix   = "burger"
location = "UK South"

vnet_address_space  = "10.0.0.0/16"
appgw_subnet_prefix = "10.0.1.0/24"
fe_subnet_prefix    = "10.0.2.0/24"
be_subnet_prefix    = "10.0.3.0/24"
pep_subnet_prefix   = "10.0.4.0/24"
ops_subnet_prefix   = "10.0.5.0/24"

db_name           = "burgerbuilder-group22"
app_service_sku   = "P1v3"
vm_admin_username = "azureuser"

# NOTE: Sensitive variables like sql_admin_username, sql_admin_password, and vm_ssh_public_key 
# should be provided via environment variables (TF_VAR_...) in GitHub Actions 
# or via a secure terraform.tfvars that is NOT committed to git.

custom_domain_name                        = "burgergroup2.com"
appgw_ssl_certificate_key_vault_secret_id = "https://burgerappgwkv.vault.azure.net/secrets/appgw-cert/6d55b9630d7c4786993ac6c7e1702306"

# Notification settings
# telegram_bot_token and telegram_chat_id should be provided via TF_VAR_... in GitHub Actions
# notification_email can be set directly here or via TF_VAR_notification_email
notification_email = "musaxasmammedov77@gmail.com"
# Temporarily add Telegram secrets for testing (remove after GitHub Secrets are configured)
# telegram_bot_token = "your-bot-token-here"
# telegram_chat_id = "your-chat-id-here"

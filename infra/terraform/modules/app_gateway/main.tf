
locals {
  backend_address_pool_name_fe    = "${var.prefix}-beap-fe"
  backend_address_pool_name_be    = "${var.prefix}-beap-be"
  frontend_port_name              = "${var.prefix}-feport"
  frontend_ip_configuration_name  = "${var.prefix}-feip"
  http_setting_name_fe            = "${var.prefix}-be-htst-fe"
  http_setting_name_be            = "${var.prefix}-be-htst-be"
  listener_name                   = "${var.prefix}-httplstn"
  https_listener_name             = "${var.prefix}-httpslstn"
  request_routing_rule_name       = "${var.prefix}-rqrt"
  https_request_routing_rule_name = "${var.prefix}-https-rqrt"
  url_path_map_name               = "${var.prefix}-urlpathmap"
  https_url_path_map_name         = "${var.prefix}-https-urlpathmap"
  ssl_certificate_name            = "${var.prefix}-appgw-cert"
  https_enabled                   = var.custom_domain_name != "" && var.appgw_ssl_certificate_key_vault_secret_id != ""
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.prefix}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.appgw_identity_id]
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  dynamic "frontend_port" {
    for_each = local.https_enabled ? [1] : []

    content {
      name = "${local.frontend_port_name}-https"
      port = 443
    }
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.appgw_public_ip_id
  }

  backend_address_pool {
    name = local.backend_address_pool_name_fe
  }

  backend_address_pool {
    name = local.backend_address_pool_name_be
  }

  probe {
    name                                      = "probe-fe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399", "401", "403"]
    }
  }

  probe {
    name                                      = "probe-be"
    protocol                                  = "Http"
    path                                      = "/api/ingredients" # Assuming this is a health check endpoint or valid api path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399", "401", "403", "404"]
    }
  }

  backend_http_settings {
    name                                = local.http_setting_name_fe
    cookie_based_affinity               = "Disabled" # Отключаем привязку сессии
    port                                = 80         # Идем к FE VMSS по HTTP порту 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    probe_name                          = "probe-fe"
  }

  backend_http_settings {
    name                                = local.http_setting_name_be
    cookie_based_affinity               = "Disabled"
    port                                = 8080 # Идем к BE VMSS по HTTP порту 8080
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    probe_name                          = "probe-be"
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  dynamic "ssl_certificate" {
    for_each = local.https_enabled ? [1] : []

    content {
      name                = local.ssl_certificate_name
      key_vault_secret_id = var.appgw_ssl_certificate_key_vault_secret_id
    }
  }

  dynamic "http_listener" {
    for_each = local.https_enabled ? [1] : []

    content {
      name                           = local.https_listener_name
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = "${local.frontend_port_name}-https"
      protocol                       = "Https"
      host_name                      = var.custom_domain_name
      ssl_certificate_name           = local.ssl_certificate_name
    }
  }

  url_path_map {
    name                               = local.url_path_map_name
    default_backend_address_pool_name  = local.backend_address_pool_name_fe
    default_backend_http_settings_name = local.http_setting_name_fe

    path_rule {
      name                       = "api-rule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = local.backend_address_pool_name_be
      backend_http_settings_name = local.http_setting_name_be
    }
  }

  request_routing_rule {
    name               = local.request_routing_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.listener_name
    url_path_map_name  = local.url_path_map_name
    priority           = 100
  }

  dynamic "url_path_map" {
    for_each = local.https_enabled ? [1] : []

    content {
      name                               = local.https_url_path_map_name
      default_backend_address_pool_name  = local.backend_address_pool_name_fe
      default_backend_http_settings_name = local.http_setting_name_fe

      path_rule {
        name                       = "api-rule-https"
        paths                      = ["/api/*"]
        backend_address_pool_name  = local.backend_address_pool_name_be
        backend_http_settings_name = local.http_setting_name_be
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.https_enabled ? [1] : []

    content {
      name               = local.https_request_routing_rule_name
      rule_type          = "PathBasedRouting"
      http_listener_name = local.https_listener_name
      url_path_map_name  = local.https_url_path_map_name
      priority           = 110
    }
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  firewall_policy_id                = azurerm_web_application_firewall_policy.waf.id
  force_firewall_policy_association = true
}

resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.prefix}-wafpolicy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

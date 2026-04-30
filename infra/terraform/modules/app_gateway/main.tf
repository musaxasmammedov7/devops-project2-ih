
locals {
  backend_address_pool_name_fe   = "${var.prefix}-beap-fe"
  backend_address_pool_name_be   = "${var.prefix}-beap-be"
  frontend_port_name             = "${var.prefix}-feport"
  frontend_ip_configuration_name = "${var.prefix}-feip"
  http_setting_name_fe           = "${var.prefix}-be-htst-fe"
  http_setting_name_be           = "${var.prefix}-be-htst-be"
  listener_name                  = "${var.prefix}-httplstn"
  request_routing_rule_name      = "${var.prefix}-rqrt"
  url_path_map_name              = "${var.prefix}-urlpathmap"
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

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
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

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}

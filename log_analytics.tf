resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                          = "loganalytics-workspace-${random_string.infra.result}"
  location                      = module.metadata.location
  resource_group_name           = azurerm_resource_group.infrastructure.name
  sku                           = "Standard"
  local_authentication_disabled = true
  retention_in_days             = 30
  tags                          = merge(module.metadata.tags, { "purpose" = "loganalytics" })
}

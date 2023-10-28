resource "azurerm_template_deployment" "dsvm_auto_deletion_perfromcounter_template" {
  name                = "dsvm-auto-deletion-perfromcounter-${random_string.dsvm_auto_deletion.result}"
  resource_group_name = azurerm_resource_group.infrastructure.name

  template_body = file("${path.module}/arm_template/perfromcounter.json")

  parameters = {
    "workspaceName" = azurerm_log_analytics_workspace.log_analytics.name,
    "location"      = azurerm_log_analytics_workspace.log_analytics.location
  }
  depends_on      = [azurerm_log_analytics_workspace.log_analytics]
  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "dsvm_auto_deletion_customlogs_template" {
  name                = "dsvm-auto-deletion-customlogs-${random_string.dsvm_auto_deletion.result}"
  resource_group_name = azurerm_resource_group.infrastructure.name

  template_body = file("${path.module}/arm_template/customlogs.json")

  parameters = {
    "workspaceName" = azurerm_log_analytics_workspace.log_analytics.name,
    "location"      = azurerm_log_analytics_workspace.log_analytics.location
  }
  depends_on      = [azurerm_log_analytics_workspace.log_analytics]
  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "customlogs_dcr_table" {
  name                = "customlogs-dcr-table-${random_string.dsvm_auto_deletion.result}"
  resource_group_name = azurerm_resource_group.infrastructure.name
  template_body       = file("${path.module}/arm_template/customlogs-dcr-table.json")
  parameters = {
    "workspaceName" = azurerm_log_analytics_workspace.log_analytics.name,
    "location"      = azurerm_log_analytics_workspace.log_analytics.location
  }
  depends_on      = [azurerm_log_analytics_workspace.log_analytics]
  deployment_mode = "Incremental"
}


resource "azurerm_template_deployment" "dsvm_auto_deletion_data_collection_rule" {
  name                = "${local.subscription}-CDCR" // Custom Data Collection Rule
  resource_group_name = azurerm_resource_group.infrastructure.name
  template_body       = file("${path.module}/arm_template/customlogs-dcr.json")
  parameters = {
    "dataCollectionRules_name"           = "${local.subscription}-CDCR",
    "dataCollectionRules_location"       = azurerm_log_analytics_workspace.log_analytics.location,
    "dataCollectionEndpoints_externalid" = azurerm_monitor_data_collection_endpoint.customlogs_data_collection_endpoint.id,
    "loganalytics_workspace_externalid"  = azurerm_log_analytics_workspace.log_analytics.id,
    "loganalytics_workspace_name"        = azurerm_log_analytics_workspace.log_analytics.name
  }
  depends_on = [azurerm_template_deployment.customlogs_dcr_table,
    azurerm_monitor_data_collection_endpoint.customlogs_data_collection_endpoint
  ]
  deployment_mode = "Incremental"
}

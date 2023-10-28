resource "azurerm_monitor_action_group" "delete_dsvm_action_group" {
  name                = "dsvm-auto-deletion-action-group"
  resource_group_name = azurerm_resource_group.dsvm_auto_deletion_resource_group.name
  short_name          = "dsvm-autodel"
  tags                = module.metadata.tags

  logic_app_receiver {
    name                    = "dsvm-auto-deletion-logicapp"
    resource_id             = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
    callback_url            = azurerm_logic_app_trigger_http_request.logic_app_httptrigger_code.callback_url
    use_common_alert_schema = true
  }

  email_receiver {
    name                    = "sendtoPraveen"
    email_address           = "kumapr15@risk.regn.net"
    use_common_alert_schema = true
  }

}
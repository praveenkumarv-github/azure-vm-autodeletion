resource "azurerm_logic_app_workflow" "dsvm_auto_deletion_logicapp" {
  name                = "dsvm-auto-deletion-logicapp"
  location            = module.metadata.location
  resource_group_name = azurerm_resource_group.dsvm_auto_deletion_resource_group.name
}

data "local_file" "httptrigger_code" {
  filename = "${path.module}/logicappflow/httpTrigger"
}

resource "azurerm_logic_app_trigger_http_request" "logic_app_httptrigger_code" {
  name         = "alertv2httPayload"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id

  schema = data.local_file.httptrigger_code.content
}

resource "azurerm_logic_app_trigger_http_request" "logic_app_httptrigger_code" {
  name         = "alertv2httPayload"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id

  schema = data.local_file.httptrigger_code.content
}

data "local_file" "json_parser_code" {
  filename = "${path.module}/logicappflow/json_parser_code"
}

resource "azurerm_logic_app_action_custom" "logic_app_jsonParser" {
  name         = "jsonParser"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id

  body = data.local_file.json_parser_code.content
}

data "local_file" "Initialize_dsvmName" {
  filename = "${path.module}/logicappflow/Initialize_dsvmName"
}

resource "azurerm_logic_app_action_custom" "Initialize_dsvmName" {
  name         = "Initialize-dsvmName"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Initialize_dsvmName.content

  depends_on = [
    azurerm_logic_app_action_custom.logic_app_jsonParser
  ]
}

data "local_file" "Initialize_requestID" {
  filename = "${path.module}/logicappflow/Initialize_requestID"
}

resource "azurerm_logic_app_action_custom" "Initialize_requestID" {
  name         = "Initialize-requestID"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Initialize_requestID.content

  depends_on = [
    azurerm_logic_app_action_custom.Initialize_dsvmName
  ]

}

data "local_file" "Initialize_resourceId" {
  filename = "${path.module}/logicappflow/Initialize_resourceId"
}

resource "azurerm_logic_app_action_custom" "Initialize_resourceId" {
  name         = "Initialize-resourceId"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Initialize_resourceId.content

  depends_on = [
    azurerm_logic_app_action_custom.Initialize_requestID
  ]
}

data "local_file" "Initialize_resourceGroup" {
  filename = "${path.module}/logicappflow/Initialize_resourceGroup"
}

resource "azurerm_logic_app_action_custom" "Initialize_resourceGroup" {
  name         = "Initialize-resourceGroup"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Initialize_resourceGroup.content

  depends_on = [
    azurerm_logic_app_action_custom.Initialize_resourceId
  ]
}

data "local_file" "Initialize_subscriptionName" {
  filename = "${path.module}/logicappflow/Initialize_subscriptionName"
}

resource "azurerm_logic_app_action_custom" "Initialize_subscriptionName" {
  name         = "Initialize-subscriptionName"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Initialize_subscriptionName.content

  depends_on = [
    azurerm_logic_app_action_custom.Initialize_resourceGroup
  ]
}

data "local_file" "Initialize_user" {
  filename = "${path.module}/logicappflow/Initialize_user"
}

resource "azurerm_logic_app_action_custom" "Initialize_user" {
  name         = "Initialize-user"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Initialize_user.content

  depends_on = [
    azurerm_logic_app_action_custom.Initialize_subscriptionName
  ]
}

data "local_file" "Compose" {
  filename = "${path.module}/logicappflow/Compose"
}

resource "azurerm_logic_app_action_custom" "Compose" {
  name         = "Compose"
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.Compose.content

  depends_on = [
    azurerm_logic_app_action_custom.Initialize_user
  ]
}

data "local_file" "DeleteDSVM" {
  filename = "${path.module}/logicappflow/DeleteDSVM"
}

resource "azurerm_logic_app_action_custom" "DeleteDSVM" {
  name         = "DeleteDSVM"
  count        = var.environment == "dev" ? 1 : 0
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.DeleteDSVM.content

  depends_on = [
    azurerm_logic_app_action_custom.Compose
  ]
}


data "local_file" "DeleteDSVM_Prod" {
  filename = "${path.module}/logicappflow/DeleteDSVM_Prod"
}
resource "azurerm_logic_app_action_custom" "DeleteDSVM_Prod" {
  name         = "DeleteDSVM_Prod"
  count        = var.environment == "prod" ? 1 : 0
  logic_app_id = azurerm_logic_app_workflow.dsvm_auto_deletion_logicapp.id
  body         = data.local_file.DeleteDSVM_Prod.content

  depends_on = [
    azurerm_logic_app_action_custom.Compose
  ]
}


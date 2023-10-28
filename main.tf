resource "azurerm_resource_group" "dsvm_auto_deletion_resource_group" {
  name     = "dsvm-auto-deletion"
  location = module.metadata.location
}

resource "random_string" "dsvm_auto_deletion" {
  length  = 4
  upper   = false
  special = false
}
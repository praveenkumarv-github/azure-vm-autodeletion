resource "azurerm_monitor_scheduled_query_rules_alert_v2" "dsvm_auto_deletion_alert_v2" {
  name                 = "-dsvm-auto-deletion-alert"
  resource_group_name  = azurerm_resource_group.dsvm_auto_deletion_resource_group.name
  location             = module.metadata.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT1H"
  scopes               = [azurerm_log_analytics_workspace.log_analytics.id]
  severity             = 4
  criteria {
    query                   = <<-QUERY
    let agedComuter = toscalar (
    Heartbeat
    | where TimeGenerated  > ago(10d)
    | summarize firstheartbeat = min(TimeGenerated) , lastheartbeat = max(TimeGenerated) by Computer //getting VM's age
    | extend age = datetime_diff('minute',lastheartbeat,firstheartbeat) //age = last heartbeat - first hearbeat // result will be minutes
    | where lastheartbeat > ago(30m) // Filter 2 : filtering only heartbeats of computer 30m ago
    | where age > 120 // Filter 3 : filtering only Computer's age greater than 50 min
    | summarize liveComputer = make_set(Computer)
    );
    let lastLogginLesserThan2hours = toscalar (
    customssh_CL
    | extend RawDataList = split(RawData,"---")
    | extend RawData = RawDataList[0]
    | extend _ResourceId = RawDataList[1]
    | extend ResourceIdList = split(_ResourceId,"/")
    | extend Computer = ResourceIdList[8]
    | extend ManagementGroupName = ResourceIdList[8]
    | project-away ResourceIdList , RawDataList
    | where Computer in (agedComuter)
    | where RawData has "risk.regn.net"
    | summarize initalLogginTImestamp = min(TimeGenerated) , lastLogginTimestamp = max(TimeGenerated) by tostring(Computer)
    | extend  howLong = (now() - lastLogginTimestamp )
    | where howLong < timespan(2h) //exclude the Computers with - lastLoggin lesser than 2 hour
    | summarize lastLogginLesserThan2h = make_set(tostring(Computer)) //exclude this List
    );
    let sshInactiveSession = toscalar (
    customssh_CL
    | extend RawDataList = split(RawData,"---")
    | extend RawData = RawDataList[0]
    | extend _ResourceId = RawDataList[1]
    | extend ResourceIdList = split(_ResourceId,"/")
    | extend Computer = ResourceIdList[8]
    | extend ManagementGroupName = ResourceIdList[8]
    | project-away ResourceIdList ,RawDataList
    | where Computer in (agedComuter)
    | where RawData has "NO-ActiveSession"
    | summarize inactiveTimeStamp = max(TimeGenerated) by tostring(Computer)
    | extend  diffinactive = now() - inactiveTimeStamp
    | where diffinactive < timespan(3m)
    | project inactiveTimeStamp , Computer , diffinactive
    | summarize sshInactivComputers = make_set(Computer)
    );
    Perf
    | where TimeGenerated  > ago(1h)
    | where Computer in (sshInactiveSession)
    | where Computer !in (lastLogginLesserThan2hours)
    | where CounterName == "% Processor Time"
    | project TimeGenerated, Computer, CounterValue, _ResourceId
    | summarize AggregatedValue = avg(CounterValue)  by bin(TimeGenerated, 1h), Computer, _ResourceId
      QUERY
    time_aggregation_method = "Maximum"
    threshold               = 30.0
    operator                = "LessThan"
    resource_id_column      = "_ResourceId"
    metric_measure_column   = "AggregatedValue"
    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled          = false
  workspace_alerts_storage_enabled = false
  description                      = "This is Alert Type v2 for  auto deletion"
  display_name                     = "dsvm-auto-deletion-alert"
  enabled                          = var.dsvm_auto_deletion_alert_v2_enabled
  query_time_range_override        = "P2D"
  skip_query_validation            = false
  action {
    action_groups = [azurerm_monitor_action_group.delete_dsvm_action_group.id]
  }
  depends_on = [
    azurerm_template_deployment.dsvm_auto_deletion_customlogs_template,
    azurerm_template_deployment.customlogs_dcr_table
  ]
  tags = module.metadata.tags

}

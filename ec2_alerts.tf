# EC2 INSTANCES TO MONITOR
# Identify instances using their AWS Name tag


locals {
  ec2_monitor_instances = {
    server01 = "xxxxxxxxx"
    # server02 = "xxxxxxxxxxx"
    # server03 = "xxxxxxxxxx"
  }

  ec2_monitor_instance_ids = flatten([
    for instance in data.aws_instances.monitored : instance.ids
  ])
}

# ============================================================
# RESOLVE EC2 INSTANCE IDS FROM AWS NAME TAGS
# ============================================================

data "aws_instances" "monitored" {
  for_each = local.ec2_monitor_instances

  instance_tags = {
    Name = each.value
  }

  instance_state_names = [
    "pending",
    "running",
    "stopping",
    "stopped"
  ]
}

# ============================================================
# 1. CPU WARNING > 85% FOR 5 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-High-CPU"
  alarm_description   = "WARNING: CPU above 85% for 5 minutes"

  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 2. CPU CRITICAL > 95% FOR 10 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_critical" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-Critical-CPU"
  alarm_description   = "CRITICAL: CPU above 95% for 10 minutes"

  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 95
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 3. MEMORY WARNING > 80% FOR 1 MINUTE
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-High-Memory"
  alarm_description   = "WARNING: Memory above 80% for 1 minute"

  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 4. MEMORY CRITICAL > 90% FOR 5 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_memory_critical" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-Critical-Memory"
  alarm_description   = "CRITICAL: Memory above 90% for 5 minutes"

  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 5. DISK WARNING > 80% FOR 1 MINUTE
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-High-Disk"
  alarm_description   = "WARNING: Disk above 80% for 1 minute"

  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 6. DISK CRITICAL > 90% FOR 10 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_disk_critical" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-Critical-Disk"
  alarm_description   = "CRITICAL: Disk above 90% for 10 minutes"

  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 10
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 7. EC2 STATUS CHECK FAILED
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_status_failed" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-Status-Check-Failed"
  alarm_description   = "CRITICAL: EC2 status check failed for 2 minutes"

  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = one(data.aws_instances.monitored[each.key].ids)
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# ============================================================
# 8. EVENTBRIDGE - EC2 STOPPED
# ============================================================

resource "aws_cloudwatch_event_rule" "ec2_stopped" {
  for_each = local.ec2_monitor_instances

  name        = "UAT-${each.key}-EC2-Stopped"
  description = "Detect ${each.value} entering stopped state"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]

    detail = {
      state         = ["stopped"]
      "instance-id" = [one(data.aws_instances.monitored[each.key].ids)]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_stopped_sns" {
  for_each = local.ec2_monitor_instances

  rule      = aws_cloudwatch_event_rule.ec2_stopped[each.key].name
  target_id = "EC2StoppedSNS"
  arn       = aws_sns_topic.lambda_alerts.arn

  input_transformer {
    input_paths = {
      instance_id = "$.detail.instance-id"
      state       = "$.detail.state"
      time        = "$.time"
      region      = "$.region"
    }

    input_template = format(
      "\"[CRITICAL] EC2 STOPPED || Environment: %s || Instance Name: %s || Instance ID: <instance_id> || State: <state> || Region: <region> || Time (UTC): <time>\"",
      var.TFC_stage,
      each.value
    )
  }
}

# ============================================================
# 9. EVENTBRIDGE - EC2 RUNNING
# ============================================================

resource "aws_cloudwatch_event_rule" "ec2_running" {
  for_each = local.ec2_monitor_instances

  name        = "UAT-${each.key}-EC2-Running"
  description = "Detect ${each.value} entering running state"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]

    detail = {
      state         = ["running"]
      "instance-id" = [one(data.aws_instances.monitored[each.key].ids)]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_running_sns" {
  for_each = local.ec2_monitor_instances

  rule      = aws_cloudwatch_event_rule.ec2_running[each.key].name
  target_id = "EC2RunningSNS"
  arn       = aws_sns_topic.lambda_alerts.arn

  input_transformer {
    input_paths = {
      instance_id = "$.detail.instance-id"
      state       = "$.detail.state"
      time        = "$.time"
      region      = "$.region"
    }

    input_template = format(
      "\"[RECOVERY] EC2 RUNNING || Environment: %s || Instance Name: %s || Instance ID: <instance_id> || State: <state> || Region: <region> || Time (UTC): <time>\"",
      var.TFC_stage,
      each.value
    )
  }
}

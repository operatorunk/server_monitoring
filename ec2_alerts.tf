# EC2 INSTANCES TO MONITOR
# Identify instances using their AWS Name tag


locals {
  ec2_monitor_instances = {
    server01 = "xxxxxxxxx"
    # server02 = "xxxxxxxxxxx"
    # server03 = "xxxxxxxxxx"
  }
}


# RESOLVE EC2 INSTANCE IDS FROM AWS NAME TAGS


data "aws_instances" "monitored" {
  for_each = local.ec2_monitor_instances

  instance_tags = {
    Name = each.value
  }

  instance_state_names = ["pending", "running", "stopping", "stopped"]
}

# ============================================================
# 1. CPU UTILIZATION > 85% FOR 10 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-High-CPU"
  alarm_description   = "CPU usage above 85% for 10 minutes"

  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
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
# 2. MEMORY UTILIZATION > 85% FOR 10 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-High-Memory"
  alarm_description   = "Memory usage above 85% for 10 minutes"

  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
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
# 3. DISK UTILIZATION > 85% FOR 10 MINUTES
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-High-Disk"
  alarm_description   = "Disk usage above 85% for 10 minutes"

  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
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
# 4. EC2 STATUS CHECK FAILED
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_status_failed" {
  for_each = local.ec2_monitor_instances

  alarm_name          = "UAT-${each.key}-Status-Check-Failed"
  alarm_description   = "EC2 instance or system status check failed"

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

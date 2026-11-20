locals {
  ec2_monitor_instance_id = "i-xxxxxxxxxxxxxxxxx"
}

# CPU > 85% durante 10 minutos
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "UAT-EC2-High-CPU"
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
    InstanceId = local.ec2_monitor_instance_id
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# Memoria > 85% durante 10 minutos
resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  alarm_name          = "UAT-EC2-High-Memory"
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
    InstanceId = local.ec2_monitor_instance_id
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# Disco > 85% durante 10 minutos
resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  alarm_name          = "UAT-EC2-High-Disk"
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
    InstanceId = local.ec2_monitor_instance_id
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

# Fallo de estado de EC2
resource "aws_cloudwatch_metric_alarm" "ec2_status_failed" {
  alarm_name          = "UAT-EC2-Status-Check-Failed"
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
    InstanceId = local.ec2_monitor_instance_id
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
  ok_actions    = [aws_sns_topic.lambda_alerts.arn]
}

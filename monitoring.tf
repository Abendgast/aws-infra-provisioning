# Requirement: Lab 11 (Observability & Alerts) - Maps to Azure Monitor spec
resource "aws_sns_topic" "alerts" {
  name = "az104-alerts-ops-team"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

resource "aws_cloudwatch_event_rule" "vm_deleted" {
  name        = "VM_Deleted_Alert"
  description = "Triggered when an EC2 instance is terminated"

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["shutting-down", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.vm_deleted.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "sns:Publish"
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}

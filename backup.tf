# Requirement: Lab 10 (Data Protection) - Maps to Azure Recovery Services spec
resource "aws_backup_vault" "primary" {
  name = "az104-rsv-region1"
}

resource "aws_backup_vault" "secondary" {
  provider = aws.dr
  name     = "az104-rsv-region2"
}

resource "aws_iam_role" "backup_role" {
  name = "AWSBackupDefaultServiceRoleAz104"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_backup_plan" "main" {
  name = "az104-backup-plan"

  rule {
    rule_name         = "DailyBackup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 0 * * ? *)" # Daily at 12:00 AM

    lifecycle {
      delete_after = 60 # Retain for 2 months
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn
      lifecycle {
        delete_after = 60
      }
    }
  }
}

resource "aws_backup_selection" "main" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "az104-vm-backup"
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_instance.core_vm.arn
  ]
}

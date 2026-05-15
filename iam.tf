# Requirement: Lab 1 (Identity Management) - Maps to Azure Entra ID spec
resource "aws_iam_user" "user1" {
  name = "az104-user1"
}

resource "aws_iam_user" "guest" {
  name = "abendgast" # Equivalent to the invited external user
}

resource "aws_iam_group" "lab_admins" {
  name = "IT-Lab-Administrators"
}

resource "aws_iam_group_membership" "lab_admins_members" {
  name  = "lab_admins_membership"
  group = aws_iam_group.lab_admins.name
  users = [
    aws_iam_user.user1.name,
    aws_iam_user.guest.name
  ]
}

# Requirement: Lab 2 (Role-Based Access Control) - Maps to Azure RBAC spec
resource "aws_iam_policy" "vm_contributor" {
  name        = "VirtualMachineContributor"
  description = "Allows managing EC2 instances"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "deny_support" {
  name        = "CustomSupportRequestDeny"
  description = "Deny creating support requests"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["support:*"]
        Effect   = "Deny"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "vm_contrib_attach" {
  group      = aws_iam_group.lab_admins.name
  policy_arn = aws_iam_policy.vm_contributor.arn
}

resource "aws_iam_group_policy_attachment" "deny_support_attach" {
  group      = aws_iam_group.lab_admins.name
  policy_arn = aws_iam_policy.deny_support.arn
}

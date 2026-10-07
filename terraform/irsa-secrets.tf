# 1. AWS Secrets Manager Secret Creation
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "postgresql-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    DB_USERNAME = aws_db_instance.postgresql.username
    DB_PASSWORD = var.db_password
  })
}

# 2. IAM Policy to allow reading the Secret
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "eks-secrets-manager-policy"
  description = "Allows EKS pods to fetch DB secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

# 3. IAM Role for Flask Application ServiceAccount
resource "aws_iam_role" "flask_sa_role" {
  name = "flask-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"

            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:default:re-build-app-sa"
          }
        }
      }
    ]
  })
}

# 4. Attach Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "attach_secrets_manager" {
  role       = aws_iam_role.flask_sa_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# 5. Output IAM Role ARN for K8s ServiceAccount
output "flask_sa_role_arn" {
  value       = aws_iam_role.flask_sa_role.arn
  description = "Annotate this ARN on your Kubernetes ServiceAccount"
}

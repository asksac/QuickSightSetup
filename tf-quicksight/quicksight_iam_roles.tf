# This configuration script creates various IAM roles and policies with well-known 
# names that QuickSight uses to access other AWS services

# More information: https://repost.aws/knowledge-center/quicksight-permission-errors 
# Accessing AWS resources: https://docs.aws.amazon.com/quicksight/latest/user/accessing-data-sources.html 

#--- Primary QuickSight Service Role

resource "aws_iam_role" "quicksight_service_role" {
  name                      = "aws-quicksight-service-role-v0" 
  path                      = "/service-role/"
  assume_role_policy        = data.aws_iam_policy_document.quicksight_assume_role_policy.json
}

data "aws_iam_policy_document" "quicksight_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["quicksight.amazonaws.com"]
    }
  }
}

#--- QuickSight S3 Policy 

resource "aws_iam_policy" "quicksight_s3_policy" {
  name                      = "AWSQuickSightS3Policy"
  path                      = "/service-role/"
  description               = "Grants Amazon QuickSight read permission to Amazon S3 resources (managed by Terraform)"

  policy                    = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Effect      = "Allow"
        Action      = ["s3:ListAllMyBuckets"]
        Resource    = "arn:aws:s3:::*"
      }, 
      {
        Effect      = "Allow"
        Action      = ["s3:ListBucket"]
        Resource    = aws_s3_bucket.data_bucket.arn
      }, 
      {
        Effect      = "Allow"
        Action      = [
          "s3:GetObject", 
          "s3:GetObjectVersion"
        ]
        Resource    = "${aws_s3_bucket.data_bucket.arn}/*"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "quicksight_s3_policy_attachment" {
  role                      = aws_iam_role.quicksight_service_role.name
  policy_arn                = aws_iam_policy.quicksight_s3_policy.arn
}

#--- QuickSight RDS Policy 

resource "aws_iam_policy" "quicksight_rds_policy" {
  name                      = "AWSQuickSightRDSPolicy"
  path                      = "/service-role/"
  description               = "Grants Amazon QuickSight describe permissions to AWS RDS resources (managed by Terraform)"

  policy                    = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Effect      = "Allow"
        Action      = ["rds:Describe*"]
        Resource    = "*"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "quicksight_rds_policy_attachment" {
  role                      = aws_iam_role.quicksight_service_role.name
  policy_arn                = aws_iam_policy.quicksight_rds_policy.arn
}

#--- QuickSight Secrets Manager Service Role

resource "aws_iam_role" "quicksight_secretsmanager_role" {
  name                      = "aws-quicksight-secretsmanager-role-v0" 
  path                      = "/service-role/"
  assume_role_policy        = data.aws_iam_policy_document.quicksight_secretsmanager_assume_role_policy.json
}

data "aws_iam_policy_document" "quicksight_secretsmanager_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["quicksight.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "quicksight_secretsmanager_policy" {
  name                      = "AWSQuickSightSecretsManagerReadOnlyPolicy"
  path                      = "/service-role/"
  description               = "Policy used by QuickSight to access SecretsManager resources (read-only) (managed by Terraform)"

  policy                    = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Effect      = "Allow"
        Action      = ["secretsmanager:GetSecretValue"]
        Resource    = "arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:*"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "quicksight_secretsmanager_policy_attachment" {
  role                      = aws_iam_role.quicksight_secretsmanager_role.name
  policy_arn                = aws_iam_policy.quicksight_secretsmanager_policy.arn
}

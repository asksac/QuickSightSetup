resource "aws_s3_bucket" "data_bucket" {
  bucket_prefix           = "${lower(var.app_shortcode)}-data-files"

  force_destroy           = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_encryption" {
  bucket                  = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_encryption_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket                  = aws_s3_bucket.data_bucket.id

  policy                  = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid = "EnforceSecureTransport",
        Effect = "Deny",
        Principal = "*",
        Action = "s3:*",
        Resource = [
            aws_s3_bucket.data_bucket.arn,
            "${aws_s3_bucket.data_bucket.arn}/*"
        ],
        Condition = {
          Bool = {
              "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid = "DisallowPresignedURL",
        Effect = "Deny",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.data_bucket.arn}/*",
        Condition = {
            StringNotEquals = {
              "s3:authType" = "REST-HEADER"
            }
        }
      }, 
      {
        Sid = "AllowOnlyOrgAccess",
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.data_bucket.arn}/*",
        Condition = {
            StringEquals = {
              "aws:PrincipalOrgID" = var.aws_org_id
            }
        }
      }, 
    ]
  })
}

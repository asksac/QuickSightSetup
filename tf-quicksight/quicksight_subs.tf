
resource "aws_quicksight_account_subscription" "subscription" {
  # account name must be unique and cannot be reused even after subscription is deleted
  account_name          = "quicksight-demo-${formatdate("YYYYMMDDhhmm", timestamp())}"
  authentication_method = "IAM_ONLY" # valid values: IAM_AND_QUICKSIGHT, IAM_ONLY and ACTIVE_DIRECTORY
  edition               = "ENTERPRISE"
  notification_email    = var.quicksight_subs_email

  lifecycle {
    ignore_changes      = [ account_name ]
  }

  provisioner "local-exec" {
    when                = destroy
    command             = "aws quicksight update-account-settings --aws-account-id ${self.id} --default-namespace default --no-termination-protection-enabled"
  }

  # just to validate if the previous local-exec took effect
  provisioner "local-exec" {
    when                = destroy
    command             = "aws quicksight describe-account-settings --aws-account-id ${self.id}"
  }
}

resource "aws_quicksight_user" "user1" {
  iam_arn               = var.quicksight_user_iam_arn
  email                 = var.quicksight_user_email
  identity_type         = "IAM"
  user_role             = "ADMIN"
  namespace             = "default"

  lifecycle {
    ignore_changes      = [ user_name ]
  }
  
  depends_on            = [ aws_quicksight_account_subscription.subscription ]
}

# ----

output "quicksight_subscription_status" {
  value                 = aws_quicksight_account_subscription.subscription.account_subscription_status
}

output "quicksight_account_name" {
  value                 = aws_quicksight_account_subscription.subscription.account_name
}
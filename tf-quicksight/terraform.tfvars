aws_profile                 = "terraform_2599" 
aws_region                  = "us-east-1"
aws_org_id                  = "o-tgobc4rosb" # Organization ID of this account
app_name                    = "QuickSightSetupDemo"
app_shortcode               = "QQSD"

s3_encryption_key_arn       = "arn:aws:kms:us-east-1:229984062599:alias/aws/s3"
vpc_id                      = "vpc-0926cf66eb5897d56" # "vpc-7eb0f404"
subnet_ids                  = [ "subnet-0229f4fcd9b00c1c5", "subnet-03b652b9ab3c22192" ] # [ "subnet-f54d7bdb", "subnet-fd9d66b0", "subnet-a04276fc" ]

quicksight_subs_email       = "ssacha+quicksight@amazon.com"

quicksight_user_iam_arn     = "arn:aws:iam::229984062599:user/sachin"
quicksight_user_email       = "ssacha+quicksight-user@amazon.com"
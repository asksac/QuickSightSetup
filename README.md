# Introduction

This project demonstates how to configure QuickSight through IaC and scripting. 

Here is the sequence of resource operations that needs to be executed in order to 
create an analysis in QuickSight: 

- Account Subscription (CreateAccountSubscription)
  - User (RegisterUser)
    - Data Source (CreateDataSource)
      - Data Set (CreateDataSet)
        - Analysis (CreateAnalysis)


# Security 

### Controlling access through Service Control Policy (SCP)

The following SCP policy can be applied on an AWS account to control access to QuickSight: 

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowQuickSightAccess",
      "Effect": "Allow",
      "Action": "quicksight:*",
      "Resource": "*"
    },
    {
      "Sid": "RestrictQuickSightDirectoryType",
      "Effect": "Deny",
      "Action": "quicksight:Subscribe",
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "quicksight:DirectoryType": [
            "microsoft_ad",
            "quicksight",
            "ad_connector"
          ]
        }
      }
    },
    {
      "Sid": "RestrictQuickSightEdition",
      "Effect": "Deny",
      "Action": "quicksight:Subscribe",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "quicksight:Edition": "standard"
        }
      }
    },
    {
      "Sid": "AllowDirectoryServicePermissionsRequiredForQuickSight",
      "Effect": "Allow",
      "Action": [
        "ds:UnauthorizeApplication",
        "ds:DescribeTrusts",
        "ds:DescribeDirectories",
        "ds:DeleteDirectory",
        "ds:CreateIdentityPoolDirectory",
        "ds:CreateAlias",
        "ds:CheckAlias",
        "ds:AuthorizeApplication"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RestrictDirectoryServiceActionsToQuickSight",
      "Effect": "Deny",
      "Action": "ds:*",
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringNotEquals": {
          "aws:CalledViaLast": "quicksight.amazonaws.com"
        }
      }
    }
  ]
}
```
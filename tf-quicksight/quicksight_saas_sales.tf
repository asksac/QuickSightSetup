resource "aws_s3_object" "saas_sales_data" {
  bucket                  = aws_s3_bucket.data_bucket.id
  key                     = "quicksight/sample-data/saas-sales/SaaS-Sales.csv"
  source                  = "${path.module}/../data/saas-sales/SaaS-Sales.csv"
  source_hash             = filemd5("${path.module}/../data/saas-sales/SaaS-Sales.csv")
}

resource "aws_s3_object" "saas_sales_manifest" {
  bucket                  = aws_s3_bucket.data_bucket.id
  key                     = "quicksight/sample-data/saas-sales/manifest.json"
  content                 = <<EOF
{
  "fileLocations": [
    {
      "URIs": [
        "s3://${aws_s3_bucket.data_bucket.id}/${aws_s3_object.saas_sales_data.key}"
      ]
    }
  ], 
  "globalUploadSettings": {
    "format": "CSV", 
    "delimiter": ",", 
    "textqualifier": "'", 
    "containsHeader": "true"
  } 
}
EOF
}

locals {
  saas_sales_dataset_map = [["Row ID", "INTEGER"], ["Order ID", "STRING"], ["Order Date", "DATETIME", "M/d/yyyy"], ["Date Key", "INTEGER"], 
    ["Contact Name", "STRING"], ["Country", "COUNTRY"], ["City", "CITY"], ["Region", "STRING"], ["Subregion", "STRING"], 
    ["Customer", "STRING"], ["Customer ID", "INTEGER"], ["Industry", "STRING"], ["Segment", "STRING"], ["Product", "STRING"], 
    ["License", "STRING"], ["Sales", "DECIMAL"], ["Quantity", "INTEGER"], ["Discount", "DECIMAL"], ["Profit", "DECIMAL"]]

  saas_sales_dataset_cast_map = [for column in local.saas_sales_dataset_map: column if contains(["INTEGER", "DECIMAL", "DATETIME"], column[1]) ]
  saas_sales_dataset_tag_map = [for column in local.saas_sales_dataset_map: column if contains(["COUNTRY", "STATE", "COUNTY", "CITY", "POSTCODE", "LONGITUDE", "LATITUDE"], column[1]) ]
}

resource "aws_quicksight_data_source" "saas_sales" {
  data_source_id          = "saas-sales-example"
  name                    = "SaaS Sales Example"

  parameters {
    s3 {
      manifest_file_location {
        bucket            = aws_s3_object.saas_sales_manifest.bucket
        key               = aws_s3_object.saas_sales_manifest.key
      }
    }
  }

  permission {
    principal             = aws_quicksight_user.user1.arn
    actions               = [
      "quicksight:PassDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:UpdateDataSource",
      "quicksight:UpdateDataSourcePermissions",
      "quicksight:DescribeDataSource",
      "quicksight:DeleteDataSource"
    ]
  }

  type                    = "S3"

  depends_on              = [ aws_quicksight_account_subscription.subscription ]
}

resource "aws_quicksight_data_set" "saas_sales" {
  data_set_id             = "saas-sales"
  name                    = "SaaS Sales Example"
  import_mode             = "SPICE"

  physical_table_map {
    physical_table_map_id = "saas-sales-physical-table"
    s3_source {
      data_source_arn     = aws_quicksight_data_source.saas_sales.arn

      dynamic "input_columns" {
        for_each          = local.saas_sales_dataset_map
        content {
          name            = input_columns.value[0]
          type            = "STRING" # input_columns.value[1]
        }
      }

      upload_settings {
        format            = "CSV"
      }
    }
  }

  logical_table_map {
    alias                 = "SaaS Sales Data"
    logical_table_map_id  = "saas-sales-logical-table"

    source {
      physical_table_id   = "saas-sales-physical-table"
    }

    dynamic "data_transforms" {
      for_each            = local.saas_sales_dataset_cast_map
      iterator            = column 

      content {
        cast_column_type_operation {
          column_name     = column.value[0]
          new_column_type = column.value[1]
          format          = column.value[1] == "DATETIME" ? column.value[2] : null
        }
      }
    }

    dynamic "data_transforms" {
      for_each            = local.saas_sales_dataset_tag_map
      iterator            = column 

      content {
        tag_column_operation {
          column_name     = column.value[0]
          tags {
            column_geographic_role = column.value[1]
          } 
        }
      }
    }
  } 

  lifecycle {
    # this is needed to avoid terraform triggering constant resource updates 
    # due to the fact that we had to split permissions into 2 blocks, as refresh
    # stage of Terraform returns a single block of permissions with all 18 actions
    ignore_changes        = [ permissions ]
  }

  # actions attribute of permissions support a maximum of 16 items, hence need 
  # to split into multiple permissions blocks
  permissions {
    principal             = aws_quicksight_user.user1.arn
    actions               = [
      "quicksight:DeleteDataSet",
      "quicksight:DescribeDataSet",
      "quicksight:PassDataSet",
      "quicksight:UpdateDataSet",

      "quicksight:CancelIngestion",
      "quicksight:CreateIngestion",
      "quicksight:DescribeIngestion", 
      "quicksight:ListIngestions",

      "quicksight:DeleteDataSetRefreshProperties",
      "quicksight:DescribeDataSetRefreshProperties",
      "quicksight:PutDataSetRefreshProperties",

      "quicksight:CreateRefreshSchedule",
      "quicksight:DeleteRefreshSchedule",
      "quicksight:DescribeRefreshSchedule",
      "quicksight:ListRefreshSchedules",
      "quicksight:UpdateRefreshSchedule",
    ]
  }

  permissions {
    principal             = aws_quicksight_user.user1.arn
    actions               = [
      "quicksight:DescribeDataSetPermissions",
      "quicksight:UpdateDataSetPermissions",
    ]
  }
}

/*

resource "local_file" "saas_sales_analysis_definition" {
  filename              = "${path.module}/temp/saas_sales_analysis_definition.json"
  content               = templatefile(
    "${path.module}/saas_sales_analysis_definition_template.json", 
    {
      dataset_arn       = aws_quicksight_data_set.saas_sales.arn
      quicksight_user_arn = aws_quicksight_user.user1.arn
    }
  )
}

data "external" "saas_sales_create_analysis" {
  depends_on            = [
    aws_quicksight_data_set.saas_sales, 
    local_file. saas_sales_analysis_definition, 
  ]

  program               = [
    "aws", "quicksight", "create-analysis",
    "--output", "json",
    "--query", "CreationStatus", 
    "--aws-account-id", local.account_id,
    "--analysis-id", uuid(),
    "--name", "SaaS Sales Analysis",
    "--cli-input-json", "file://${path.module}/temp/saas_sales_analysis_definition.json"
  ]
}

output "saas_sales_create_analysis_output" {
  value                 = data.external.saas_sales_create_analysis.result
}
*/

# --- 

data "external" "saas_sales_create_analysis" {
  program               = ["python3", "${path.module}/../scripts/create_analysis.py"]
  query                 = {
    aws_region          = var.aws_region
    aws_profile         = var.aws_profile
    aws_account_id      = local.account_id
    template_file       = "${path.module}/saas_sales_analysis_definition_template.json"
    dataset_arn         = aws_quicksight_data_set.saas_sales.arn
    quicksight_user_arn = aws_quicksight_user.user1.arn
    analysis_id         = "saas-sales-analysis"
    analysis_name       = "SaaS Sales Analysis"
  }

  depends_on            = [ aws_quicksight_data_set.saas_sales ]
}

output "saas_sales_create_analysis_output" {
  value                 = data.external.saas_sales_create_analysis.result
}


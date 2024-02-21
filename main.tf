resource "aws_cloudwatch_log_group" "opensearch_log_group_index_slow_logs" {
  name              = "/aws/opensearch/${var.domain}/index-slow"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_search_slow_logs" {
  name              = "/aws/opensearch/${var.domain}/search-slow"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_es_application_logs" {
  name              = "/aws/opensearch/${var.domain}/es-application"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_resource_policy" "opensearch_log_resource_policy" {
  policy_name     = "${var.domain}-domain-log-resource-policy"
  policy_document = <<CONFIG
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Action": [
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogStream"
        ],
        "Resource": [
          "${aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs.arn}:*",
          "${aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs.arn}:*",
          "${aws_cloudwatch_log_group.opensearch_log_group_es_application_logs.arn}:*"
        ],
        "Condition": {
            "StringEquals": {
                "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
            },
            "ArnLike": {
                "aws:SourceArn": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}"
            }
        }
      }
    ]
  }
  CONFIG
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "opensearch_master_user" {
  name        = "/service/${var.service}/MASTER_USER"
  description = "opensearch_password for ${var.service} domain"
  type        = "SecureString"
  value       = "${var.master_user}, ${random_password.password.result}"
}
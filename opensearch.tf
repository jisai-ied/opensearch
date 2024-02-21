locals {
  subnet_ids = slice(data.terraform_remote_state.core.outputs.subnet_private_ids, 0, var.instance_count)
}

resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.domain
  engine_version = "OpenSearch_${var.engine_version}"

  cluster_config {
    dedicated_master_count   = var.dedicated_master_count
    dedicated_master_type    = var.dedicated_master_type
    dedicated_master_enabled = var.dedicated_master_enabled

    instance_type  = var.instance_type
    instance_count = var.instance_count

    zone_awareness_enabled = var.zone_awareness_enabled
    zone_awareness_config {
      availability_zone_count = var.zone_awareness_enabled ? length(local.subnet_ids) : null
    }
  }

  advanced_security_options {
    enabled                        = var.security_options_enabled
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = var.master_user
      master_user_password = random_password.password.result
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"

    custom_endpoint_enabled = false
  }

  ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.ebs_volume_size
    volume_type = var.volume_type
    throughput  = var.throughput
  }
    /*
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_log_group_es_application_logs
    log_type                 = "ES_APPLICATION_LOGS"
  }
  */

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids = local.subnet_ids

    security_group_ids = [data.terraform_remote_state.core.outputs.aws_security_group_aos_sg_id, ]
  }

  access_policies = <<CONFIG
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "es:*",
                "Principal": "*",
                "Effect": "Allow",
                "Resource": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"
            }
        ]
    }
  CONFIG
}

resource "aws_route53_record" "opensearch_domain_record" {
  zone_id = var.hosted_zone_id
  name =   var.domain
  type = "CNAME"
  ttl = "300"

  records = [ aws_opensearch_domain.opensearch.endpoint ]
}
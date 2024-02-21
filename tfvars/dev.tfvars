environment="dev"
hosted_zone_id = "Z082107237P5TOWSIU49X"

service = "opensearch"

domain = "opensearch-engine-test"
engine_version = "2.11"

ebs_enabled = true
ebs_volume_size = 100
volume_type = "gp3"
throughput = 125
instance_count = 1
instance_type = "t3.small.search"
zone_awareness_enabled = false

dedicated_master_enabled = false
dedicated_master_count = 0
dedicated_master_type = "m6g.large.search"

master_user = "master_user"
security_options_enabled = true
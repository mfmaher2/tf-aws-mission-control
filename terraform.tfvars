cluster_name           = "missioncontrol-al2023"
region                 = "us-west-2"
user_email             = "user.name@address.com"
license_id             = "xxxxxxxxx"

loki_bucket            = "your-loki-s3-bucket-name"
mimir_bucket           = "your-mimir-s3-bucket-name"
helm_override_file     = "mission-control-values/override.yaml"

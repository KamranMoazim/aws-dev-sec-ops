project                     = "devsecops"
region                      = "us-east-1"
vpc_cidr                    = "10.10.0.0/16"
availability_zones          = ["us-east-1a", "us-east-1b", "us-east-1c"]
single_nat_gateway          = true
secret_recovery_window_days = 0
teardown_friendly           = true

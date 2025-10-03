data "external" "latest_snapshot" {
  program = ["bash", "${path.module}/find_latest_snapshot.sh"]
  query = {
    cluster_id = var.database_name
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.database_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "this" {
  cluster_identifier     = var.database_name
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "16.3"
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  # 1. Use the new variable to control skipping the final snapshot
  skip_final_snapshot = var.skip_final_snapshot

  # 2. If we are creating a final snapshot, give it a unique name with a timestamp
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.database_name}-final-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  # 3. If restoring, use the ID from our data source. Otherwise, create a new cluster.
  #    This also correctly handles the very first run when no snapshot exists.
  snapshot_identifier = contains(["", "none"], try(data.external.latest_snapshot.result.id, "")) ? null : data.external.latest_snapshot.result.id  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  serverlessv2_scaling_configuration {
    max_capacity             = var.max_capacity
    min_capacity             = var.min_capacity
    seconds_until_auto_pause = var.seconds_until_auto_pause
  }
}


resource "aws_rds_cluster_instance" "this" {
  count = 1

  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless" # This is the required instance class for Serverless v2
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
}
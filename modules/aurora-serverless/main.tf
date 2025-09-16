resource "aws_db_subnet_group" "this" {
  name       = "${var.database_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = var.database_name
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "13.7"
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.security_group_ids
  skip_final_snapshot     = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1
  }
}
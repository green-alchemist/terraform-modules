resource "aws_db_subnet_group" "this" {
  name       = "${var.database_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "this" {
  cluster_identifier     = var.database_name
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "14.6"
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  skip_final_snapshot    = true

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
    # seconds_until_auto_pause = var.seconds_until_auto_pause
  }
}


resource "aws_rds_cluster_instance" "this" {
  count = 1

  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless" # This is the required instance class for Serverless v2
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
}
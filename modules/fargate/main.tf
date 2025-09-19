resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.ecr_repository_url
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      environment = var.environment_variables
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
  }

  # This dynamic block will create the necessary configuration
  # based on the variable we just defined.
  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }
  service_registries {
    registry_arn = var.enable_service_discovery ? aws_service_discovery_service.this[0].arn : null
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.task_family}"
}

resource "aws_appautoscaling_target" "this" {
  count              = var.enable_autoscaling ? 1 : 0
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on         = [aws_ecs_service.this]
}

# This policy tells the service how to scale UP
resource "aws_appautoscaling_policy" "scale_up" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.service_name}-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# This policy tells the service how to scale DOWN
resource "aws_appautoscaling_policy" "scale_down" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.service_name}-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# Create a private DNS namespace for service discovery (e.g., ".internal")
resource "aws_service_discovery_private_dns_namespace" "this" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.private_dns_namespace
  vpc   = var.vpc_id
}

# Register the ECS service with the DNS namespace
resource "aws_service_discovery_service" "this" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.service_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this[0].id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
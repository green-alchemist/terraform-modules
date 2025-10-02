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
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.ecr_repository_url
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true
      portMappings = [
        {
          name          = "${var.service_name}"
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = var.service_name
        }
      }
      secrets : [
        for key, value_from in var.container_secrets : {
          name : key,
          valueFrom : value_from
        }
      ],
      environment = [
        for name, value in var.environment_variables : {
          name  = name
          value = value
        }
      ]
      healthCheck = var.health_check_enabled ? {
        command     = var.health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      } : null
      linuxParameters = {
        initProcessEnabled = var.enable_execute_command
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name                   = var.service_name
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command

  deployment_minimum_healthy_percent = 0   # Allow scaling to zero
  deployment_maximum_percent         = 200 # Default, for safety during scale-up

  network_configuration {
    assign_public_ip = var.assign_public_ip
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
  }

  # service_connect_configuration {
  #   enabled   = var.service_connect_enabled
  #   namespace = var.service_connect_namespace_arn

  #   service {
  #     port_name = var.service_name
  #     # You can optionally define client aliases for different connection protocols
  #     dynamic "client_alias" {
  #       for_each = var.service_connect_enabled != null ? [1] : []
  #       content {
  #         port = var.container_port
  #       }
  #     }
  #   }
  # }
  service_registries {
    registry_arn   = aws_service_discovery_service.this[0].arn
    container_name = "strapi-admin"
    container_port = 1337
  }

  depends_on = [aws_service_discovery_service.this]
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


resource "aws_appautoscaling_policy" "scale" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_utilization_low_threshold # New variable
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization" # Valid metric
    }
    scale_in_cooldown     = var.scale_in_cooldown  # 5 min to prevent rapid scale-down
    scale_out_cooldown    = var.scale_out_cooldown # Fast scale-up from zero
  }
}



# Create a private DNS namespace for service discovery (e.g., ".internal")
resource "aws_service_discovery_private_dns_namespace" "this" {
  count = var.service_connect_enabled ? 1 : 0
  name  = var.private_dns_namespace
  vpc   = var.vpc_id
}

# # Register the ECS service with the DNS namespace
resource "aws_service_discovery_service" "this" {
  count = var.service_connect_enabled ? 1 : 0
  name  = var.service_name

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.this[0].id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 60
      type = "SRV" # Use 'A' records for IP-based discovery
    }
  }
  force_destroy = true

  health_check_custom_config {
    failure_threshold = 1 # ECS controls health
  }
}

# --- CloudWatch Alarms for Auto Scaling ---

# resource "aws_cloudwatch_metric_alarm" "scale_up" {
#   count               = var.enable_autoscaling ? 1 : 0
#   alarm_name          = "${var.service_name}-scale-up"
#   alarm_description   = "Trigger scale-up of ${var.service_name} due to high CPU utilization"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60" # Scale up quickly
#   statistic           = "Average"
#   threshold           = var.cpu_utilization_high_threshold
#   dimensions = {
#     ClusterName = aws_ecs_cluster.this.name
#     ServiceName = aws_ecs_service.this.name
#   }
#   alarm_actions = [aws_appautoscaling_policy.scale[0].arn]
# }

# resource "aws_cloudwatch_metric_alarm" "scale_down" {
#   count               = var.enable_autoscaling ? 1 : 0
#   alarm_name          = "${var.service_name}-scale-down"
#   alarm_description   = "Trigger scale-down of ${var.service_name} due to low CPU utilization"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = var.scale_down_evaluation_periods # Use our new variable (3 periods)
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = var.scale_down_period_seconds # Use our new variable (5 minutes)
#   statistic           = "Average"
#   threshold           = var.cpu_utilization_low_threshold # Use our new variable (10%)
#   dimensions = {
#     ClusterName = aws_ecs_cluster.this.name
#     ServiceName = aws_ecs_service.this.name
#   }
#   alarm_actions = [aws_appautoscaling_policy.scale[0].arn]
# }


# This policy tells the service how to scale DOWN
# resource "aws_appautoscaling_policy" "scale_down" {
#   count              = var.enable_autoscaling ? 1 : 0
#   name               = "${var.service_name}-scale-down"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.this[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.this[0].service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 300
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       metric_interval_upper_bound = 0
#       scaling_adjustment          = -1
#     }
#   }
# }


# # This policy tells the service how to scale UP
# resource "aws_appautoscaling_policy" "scale_up" {
#   count              = var.enable_autoscaling ? 1 : 0
#   name               = "${var.service_name}-scale-up"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.this[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.this[0].service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       metric_interval_lower_bound = 0
#       scaling_adjustment          = 1
#     }
#   }
# }
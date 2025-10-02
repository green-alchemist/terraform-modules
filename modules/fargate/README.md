## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_service_discovery_private_dns_namespace.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether to assign a public IP to the Fargate task. | `bool` | `false` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where the resources are located. | `string` | `"us-east-1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the ECS cluster. | `string` | n/a | yes |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | The name of the container. | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port on the container to expose. | `number` | `1337` | no |
| <a name="input_container_secrets"></a> [container\_secrets](#input\_container\_secrets) | A map of secret environment variables to set. The key is the variable name, the value is the full ARN of the SSM Parameter Store parameter. | `map(string)` | `{}` | no |
| <a name="input_cpu_utilization_high_threshold"></a> [cpu\_utilization\_high\_threshold](#input\_cpu\_utilization\_high\_threshold) | The CPU utilization percentage to trigger a scale-up event. | `number` | `75` | no |
| <a name="input_cpu_utilization_low_threshold"></a> [cpu\_utilization\_low\_threshold](#input\_cpu\_utilization\_low\_threshold) | The CPU utilization percentage to trigger a scale-down event. This should be low for scale-to-zero. | `number` | `20` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The number of instances of the task to run. | `number` | `1` | no |
| <a name="input_ecr_repository_url"></a> [ecr\_repository\_url](#input\_ecr\_repository\_url) | The URL of the ECR repository. | `string` | n/a | yes |
| <a name="input_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#input\_ecs\_task\_execution\_role\_arn) | The ARN of the IAM role that allows ECS tasks to make API calls. | `string` | n/a | yes |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | If true, enables auto-scaling for the Fargate service. | `bool` | `false` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Specifies whether to enable Amazon ECS Exec for the tasks within the service. | `bool` | `false` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | A map of environment variables to pass to the container. | `map(string)` | `{}` | no |
| <a name="input_health_check_command"></a> [health\_check\_command](#input\_health\_check\_command) | The command to run for the health check. | `list(string)` | <pre>[<br/>  "CMD-SHELL",<br/>  "curl -f http://localhost:1337/admin || exit 1"<br/>]</pre> | no |
| <a name="input_health_check_enabled"></a> [health\_check\_enabled](#input\_health\_check\_enabled) | Enable container health checks. | `bool` | `true` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | The time period in seconds between each health check. | `number` | `30` | no |
| <a name="input_health_check_retries"></a> [health\_check\_retries](#input\_health\_check\_retries) | The number of consecutive failed health checks that must occur before a container is considered unhealthy. | `number` | `3` | no |
| <a name="input_health_check_start_period"></a> [health\_check\_start\_period](#input\_health\_check\_start\_period) | The grace period in seconds during which failed health checks are ignored when a task has just started. | `number` | `0` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | The time period in seconds to wait for a health check to succeed before it is considered a failure. | `number` | `5` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | A list of load balancer configurations to attach to the service. | <pre>list(object({<br/>    target_group_arn = string<br/>    container_name   = string<br/>    container_port   = number<br/>  }))</pre> | `[]` | no |
| <a name="input_max_tasks"></a> [max\_tasks](#input\_max\_tasks) | The maximum number of tasks for auto-scaling. | `number` | `1` | no |
| <a name="input_min_tasks"></a> [min\_tasks](#input\_min\_tasks) | The minimum number of tasks for auto-scaling. | `number` | `0` | no |
| <a name="input_private_dns_namespace"></a> [private\_dns\_namespace](#input\_private\_dns\_namespace) | The name of the private DNS namespace (e.g., 'internal'). | `string` | `"internal"` | no |
| <a name="input_scale_down_evaluation_periods"></a> [scale\_down\_evaluation\_periods](#input\_scale\_down\_evaluation\_periods) | The number of consecutive periods the scale-down metric must be low to trigger an alarm. | `number` | `3` | no |
| <a name="input_scale_down_period_seconds"></a> [scale\_down\_period\_seconds](#input\_scale\_down\_period\_seconds) | The period in seconds over which to evaluate the scale-down metric. | `number` | `300` | no |
| <a name="input_scale_in_cooldown"></a> [scale\_in\_cooldown](#input\_scale\_in\_cooldown) | Scale in cooldown, down | `number` | `300` | no |
| <a name="input_scale_out_cooldown"></a> [scale\_out\_cooldown](#input\_scale\_out\_cooldown) | Scale out cooldown, up | `number` | `60` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | A list of security group IDs to associate with the service. | `list(string)` | n/a | yes |
| <a name="input_service_connect_enabled"></a> [service\_connect\_enabled](#input\_service\_connect\_enabled) | If true, registers the service with AWS Cloud Map. | `bool` | `false` | no |
| <a name="input_service_discovery_health_check_enabled"></a> [service\_discovery\_health\_check\_enabled](#input\_service\_discovery\_health\_check\_enabled) | If true, enables custom health checking for the AWS Cloud Map service. If false, Cloud Map will not perform health checks. | `bool` | `false` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the ECS service. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs to associate with the service. | `list(string)` | n/a | yes |
| <a name="input_target_request_count"></a> [target\_request\_count](#input\_target\_request\_count) | Target average requests per second per task to trigger scaling. | `number` | `10` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | The number of CPU units used by the task. | `number` | `1024` | no |
| <a name="input_task_family"></a> [task\_family](#input\_task\_family) | The family of the ECS task definition. | `string` | n/a | yes |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | The amount of memory (in MiB) used by the task. | `number` | `2048` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | The ARN of the IAM role that allows ECS tasks to make API calls. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to deploy the service into. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the ECS cluster. |
| <a name="output_container_port"></a> [container\_port](#output\_container\_port) | The port exposed by the container. |
| <a name="output_service_arn"></a> [service\_arn](#output\_service\_arn) | The ARN of the ECS service. |
| <a name="output_service_discovery_arn"></a> [service\_discovery\_arn](#output\_service\_discovery\_arn) | The ARN of the Service Discovery service, for use in API Gateway integrations. |
| <a name="output_service_discovery_dns_name"></a> [service\_discovery\_dns\_name](#output\_service\_discovery\_dns\_name) | The private DNS name of the service. |
| <a name="output_service_discovery_id"></a> [service\_discovery\_id](#output\_service\_discovery\_id) | The ID of the Cloud Map service. |
| <a name="output_service_discovery_namespace"></a> [service\_discovery\_namespace](#output\_service\_discovery\_namespace) | Cloud Map namespace for Service Connect. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the ECS service. |

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.13.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_rds_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [external_external.latest_snapshot](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the database to create. | `string` | n/a | yes |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | A list of log types to export to CloudWatch Logs. For PostgreSQL, common values are 'postgresql' and 'upgrade'. | `list(string)` | <pre>[<br/>  "postgresql"<br/>]</pre> | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | The password for the master database user. | `string` | n/a | yes |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | The username for the master database user. | `string` | n/a | yes |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | The maximum capacity for the Aurora Serverless v1 cluster. | `number` | `1` | no |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | The minimum capacity for the Aurora Serverless v1 cluster. | `number` | `0` | no |
| <a name="input_restore_from_latest_snapshot"></a> [restore\_from\_latest\_snapshot](#input\_restore\_from\_latest\_snapshot) | If true, the cluster will be created from the most recent available snapshot. | `bool` | `false` | no |
| <a name="input_seconds_until_auto_pause"></a> [seconds\_until\_auto\_pause](#input\_seconds\_until\_auto\_pause) | The time, in seconds, before an idle cluster is paused. | `number` | `600` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | A list of security group IDs to associate with the database. | `list(string)` | n/a | yes |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB cluster is deleted. | `bool` | `false` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs to associate with the database. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The endpoint of the RDS cluster. |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | The port of the RDS cluster. |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | The name of the database. |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | The master\_username of the database. |

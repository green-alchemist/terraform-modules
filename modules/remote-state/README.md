## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_s3_bucket.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dynamodb_enable_server_side_encryption"></a> [dynamodb\_enable\_server\_side\_encryption](#input\_dynamodb\_enable\_server\_side\_encryption) | Whether or not to enable encryption at rest using an AWS managed KMS customer master key (CMK) | `bool` | `false` | no |
| <a name="input_dynamodb_table_billing_mode"></a> [dynamodb\_table\_billing\_mode](#input\_dynamodb\_table\_billing\_mode) | Controls how you are charged for read and write throughput and how you manage capacity. | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | The name of the DynamoDB table to use for state locking. | `string` | `"tf-remote-state-lock"` | no |
| <a name="input_iam_policy_attachment_name"></a> [iam\_policy\_attachment\_name](#input\_iam\_policy\_attachment\_name) | The name of the attachment. | `string` | `"tf-iam-role-attachment-replication-configuration"` | no |
| <a name="input_iam_policy_name_prefix"></a> [iam\_policy\_name\_prefix](#input\_iam\_policy\_name\_prefix) | Creates a unique name beginning with the specified prefix. | `string` | `"tf-remote-state-replication-policy"` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Use IAM role of specified ARN for s3 replication instead of creating it. | `string` | `null` | no |
| <a name="input_iam_role_name_prefix"></a> [iam\_role\_name\_prefix](#input\_iam\_role\_name\_prefix) | Creates a unique name beginning with the specified prefix. | `string` | `"tf-remote-state-replication-role"` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | Use permissions\_boundary with the replication IAM role. | `string` | `null` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | A list of lifecycle rules to apply to the bucket. | <pre>list(object({<br/>    id                                 = string<br/>    enabled                            = bool<br/>    prefix                             = string<br/>    noncurrent_version_expiration_days = number<br/>    # Add a new optional block for transitions<br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days = number<br/>      storage_class   = string<br/>      })), [])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "enabled": true,<br/>    "id": "main",<br/>    "noncurrent_version_expiration_days": 90,<br/>    "noncurrent_version_transitions": [<br/>      {<br/>        "noncurrent_days": 30,<br/>        "storage_class": "STANDARD_IA"<br/>      }<br/>    ],<br/>    "prefix": ""<br/>  }<br/>]</pre> | no |
| <a name="input_override_s3_bucket_name"></a> [override\_s3\_bucket\_name](#input\_override\_s3\_bucket\_name) | override s3 bucket name to disable bucket\_prefix and create bucket with static name | `bool` | `false` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | A boolean that indicates all objects should be deleted from S3 buckets so that the buckets can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | If override\_s3\_bucket\_name is true, use this bucket name instead of dynamic name with bucket\_prefix | `string` | `""` | no |
| <a name="input_s3_logging_target_bucket"></a> [s3\_logging\_target\_bucket](#input\_s3\_logging\_target\_bucket) | The name of the bucket for log storage. The "S3 log delivery group" should have Objects-write und ACL-read permissions on the bucket. | `string` | `null` | no |
| <a name="input_s3_logging_target_prefix"></a> [s3\_logging\_target\_prefix](#input\_s3\_logging\_target\_prefix) | The prefix to apply on bucket logs, e.g "logs/". | `string` | `""` | no |
| <a name="input_state_bucket_prefix"></a> [state\_bucket\_prefix](#input\_state\_bucket\_prefix) | Creates a unique state bucket name beginning with the specified prefix. | `string` | `"tf-remote-state"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to resources. | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_table"></a> [dynamodb\_table](#output\_dynamodb\_table) | The DynamoDB table to manage lock states. |
| <a name="output_state_bucket"></a> [state\_bucket](#output\_state\_bucket) | The S3 bucket to store the remote state file. |

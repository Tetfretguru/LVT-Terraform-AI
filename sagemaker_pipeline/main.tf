locals {
  # 1. Map of all processing steps definitions (JSON objects)
  processing_steps_json = { for step in var.processing_steps : step.name => {
    Name      = step.name
    Type      = "Processing"
    DependsOn = step.depends_on
    RetryPolicies = var.retry_policy != null ? [
      {
        BackoffRate     = var.retry_policy.backoff_rate
        IntervalSeconds = var.retry_policy.interval_seconds
        MaxAttempts     = var.retry_policy.max_attempts
        ExceptionType   = var.retry_policy.exception_types
      }
    ] : []
    Arguments = {
      ProcessingResources = {
        ClusterConfig = {
          InstanceType   = jsondecode(can(regex("^param:", step.instance_type)) ? jsonencode({ "Get" : "Parameters.${substr(step.instance_type, 6, -1)}" }) : jsonencode(step.instance_type))
          InstanceCount  = step.instance_count
          VolumeSizeInGB = step.volume_size_gb
        }
      }
      AppSpecification = {
        ImageUri            = step.image_uri
        ContainerEntrypoint = step.entrypoint
        ContainerArguments  = [for arg in step.arguments : jsondecode(can(regex("^param:", arg)) ? jsonencode({ "Get" : "Parameters.${substr(arg, 6, -1)}" }) : jsonencode(arg))]
      }
      RoleArn = var.role_arn
      ProcessingInputs = [for input in step.inputs : {
        InputName = input.input_name
        S3Input = {
          S3Uri       = jsondecode(can(regex("^param:", input.s3_uri)) ? jsonencode({ "Get" : "Parameters.${substr(input.s3_uri, 6, -1)}" }) : jsonencode(input.s3_uri))
          LocalPath   = input.local_path
          S3DataType  = input.s3_data_type
          S3InputMode = input.s3_input_mode
        }
      }]
      ProcessingOutputConfig = {
        Outputs = [for output in step.outputs : {
          OutputName = output.output_name
          S3Output = {
            S3Uri        = jsondecode(can(regex("^param:", output.s3_uri)) ? jsonencode({ "Get" : "Parameters.${substr(output.s3_uri, 6, -1)}" }) : jsonencode(output.s3_uri))
            LocalPath    = output.local_path
            S3UploadMode = output.s3_upload_mode
          }
        }]
      }
      Environment = step.environment
      NetworkConfig = step.network_config != null ? {
        EnableNetworkIsolation = step.network_config.enable_network_isolation
        VpcConfig = step.network_config.vpc_config != null ? {
          SecurityGroupIds = step.network_config.vpc_config.security_group_ids
          Subnets          = step.network_config.vpc_config.subnets
        } : null
      } : null
      StoppingCondition = {
        MaxRuntimeInSeconds = step.timeout_seconds
      }
    }
  } }

  # 2. Identify steps that are nested inside conditions
  nested_step_names = flatten([
    for c in var.condition_steps : concat(c.if_steps, c.else_steps)
  ])

  # 3. Identify top-level processing steps (those NOT nested)
  top_level_processing_step_names = [
    for step in var.processing_steps : step.name if !contains(local.nested_step_names, step.name)
  ]
}

resource "aws_sagemaker_pipeline" "sagemaker_pipeline" {
  pipeline_name         = var.pipeline_name
  pipeline_display_name = var.pipeline_display_name != null ? var.pipeline_display_name : var.pipeline_name
  role_arn              = var.role_arn

  pipeline_definition = jsonencode({
    Version = "2020-12-01"

    Parameters = [for p in var.pipeline_parameters : {
      Name         = p.name
      Type         = p.type
      DefaultValue = p.default_value
    }]

    Steps = concat(
      # Add Top Level Processing Steps
      [for name in local.top_level_processing_step_names : local.processing_steps_json[name]],
      
      # Add Condition Steps
      [for cond in var.condition_steps : {
        Name      = cond.name
        Type      = "Condition"
        DependsOn = cond.depends_on
        Arguments = {
          Conditions = [for c in cond.conditions : {
            "Condition${c.type}" = {
              LeftValue  = jsondecode(can(regex("^param:", c.left_value)) ? jsonencode({ "Get" : "Parameters.${substr(c.left_value, 6, -1)}" }) : jsonencode(c.left_value))
              RightValue = jsondecode(can(regex("^param:", c.right_value)) ? jsonencode({ "Get" : "Parameters.${substr(c.right_value, 6, -1)}" }) : jsonencode(c.right_value))
            }
          }]
          IfSteps   = [for name in cond.if_steps : local.processing_steps_json[name]]
          ElseSteps = [for name in cond.else_steps : local.processing_steps_json[name]]
        }
      }]
    )
  })
}

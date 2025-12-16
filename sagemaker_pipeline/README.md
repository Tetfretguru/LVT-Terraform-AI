# SageMaker Pipeline Terraform Module

This module allows you to create dynamic SageMaker Pipelines using Terraform. It supports processing steps (`ProcessingStep`), conditions (`ConditionStep`), execution parameters, retry policies, and automated scheduling via EventBridge.

## Features

- **Dynamic Steps:** Define any number of processing steps in a list.
- **Dependencies:** Control execution order with `depends_on`.
- **Conditions:** Implement conditional logic (If/Else) based on parameters or outputs from previous steps.
- **Pipeline Parameters:** Inject runtime values (e.g., S3 paths, instance types).
- **Scheduling:** Built-in support for scheduling pipeline executions using Cron expressions.
- **`param:` Syntax:** Easily reference pipeline parameters in arguments, URIs, and instance types.

## Basic Usage

```hcl
module "sagemaker_pipeline" {
  source = "git::https://github.com/Tetfretguru/LVT-Terraform-AI.git//sagemaker_pipeline?ref=main"

  pipeline_name = "my-ml-pipeline"
  role_arn      = "arn:aws:iam::123456789012:role/SageMakerRole"

  # 1. Define Parameters (Runtime variables)
  pipeline_parameters = [
    {
      name          = "InputData"
      type          = "String"
      default_value = "s3://bucket/data.csv"
    }
  ]

  # 2. Define Processing Steps
  processing_steps = [
    {
      name           = "Preprocessing"
      image_uri      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-image:latest"
      entrypoint     = ["python", "preprocess.py"]
      arguments      = ["--input", "param:InputData"] # Uses the parameter defined above
      instance_type  = "ml.m5.xlarge"
    },
    {
      name           = "Training"
      depends_on     = ["Preprocessing"] # Runs after Preprocessing
      image_uri      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-image:latest"
      entrypoint     = ["python", "train.py"]
      instance_type  = "ml.p3.2xlarge"
    }
  ]
}
```

## Scheduling

You can schedule the pipeline to run automatically using a Cron expression.

```hcl
module "sagemaker_pipeline" {
  # ... other configuration ...

  # Run every day at 12:00 UTC
  schedule_expression = "cron(0 12 * * ? *)"
}
```

### How Scheduling Works (Under the Hood)

When you provide a `schedule_expression`, the module automatically provisions the necessary AWS infrastructure to trigger your pipeline:

1.  **EventBridge Rule**: Creates an `aws_cloudwatch_event_rule` with the specified cron expression.
2.  **IAM Role**: Creates a dedicated IAM role (`aws_iam_role`) that trusts the EventBridge service (`events.amazonaws.com`).
3.  **IAM Policy**: Attaches a policy allowing `sagemaker:StartPipelineExecution` on your specific pipeline ARN.
4.  **Event Target**: Configures the EventBridge rule to target your SageMaker Pipeline, using the created role to authorize the execution.

This ensures a secure and self-contained setup without needing manual IAM configuration for the scheduler.

## Advanced Usage: Conditions

To execute steps only if a condition is met (e.g., Accuracy > 0.8):

```hcl
  # ... (inside the module)

  condition_steps = [
    {
      name       = "CheckAccuracy"
      depends_on = ["Training"]
      conditions = [
        {
          type        = "GreaterThanOrEqualTo"
          left_value  = "param:Accuracy" # Or output from a previous step
          right_value = "0.8"
        }
      ]
      if_steps   = ["RegisterModel"] # Steps to run if TRUE
      else_steps = ["NotifyFailure"] # Steps to run if FALSE
    }
  ]
```

> **Note:** The steps listed in `if_steps` and `else_steps` must be defined in `processing_steps`. The module handles the correct nesting in the JSON definition.

## Variable Reference

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `pipeline_name` | Unique name of the pipeline in SageMaker | `string` | Required |
| `role_arn` | ARN of the IAM execution role | `string` | Required |
| `processing_steps` | List of step configurations | `list(object)` | `[]` |
| `condition_steps` | List of condition configurations | `list(object)` | `[]` |
| `pipeline_parameters` | Pipeline parameter definitions | `list(object)` | `[]` |
| `retry_policy` | Global retry policy for steps | `object` | `null` |
| `schedule_expression` | Cron expression for auto-execution | `string` | `null` |

### `param:` Syntax

The module automatically detects the `param:` prefix in the following fields to generate the `{"Get": "Parameters.Name"}` reference:
- `instance_type`
- `s3_uri` (in inputs and outputs)
- `arguments` (in container arguments)
- `left_value` / `right_value` (in conditions)

Example: `s3_uri = "param:InputUrl"` becomes a reference to the parameter `InputUrl`.

variable "pipeline_name" {
  description = "The name of the SageMaker Pipeline"
  type        = string
}

variable "pipeline_display_name" {
  description = "The display name of the SageMaker Pipeline"
  type        = string
  default     = null
}

variable "role_arn" {
  description = "The ARN of the IAM role used to execute the pipeline"
  type        = string
}

variable "pipeline_parameters" {
  description = "List of parameters for the pipeline"
  type = list(object({
    name          = string
    type          = string
    default_value = string
  }))
  default = []
}

variable "retry_policy" {
    description = "Retry policy for the pipeline"
    type = object({
        max_attempts = number
        interval_seconds = number
        backoff_rate = number
        # Valid exception types: "Step.SERVICE_FAULT", "Step.THROTTLING", "SageMaker.JOB_INTERNAL_ERROR", "SageMaker.CAPACITY_ERROR", "SageMaker.RESOURCE_LIMIT"
        exception_types = optional(list(string), ["Step.SERVICE_FAULT"])

    })
    default = null
  
}

variable "processing_steps" {
  description = "List of processing step configurations"
  type = list(object({
    name           = string
    image_uri      = string
    entrypoint     = list(string)
    arguments      = list(string)
    instance_type  = optional(string, "ml.m5.xlarge")
    instance_count = optional(number, 1)
    volume_size_gb = optional(number, 30)
    environment    = optional(map(string), {})
    timeout_seconds  = optional(number, 14400) # 4 hours
    depends_on     = optional(list(string), [])
    inputs = optional(list(object({
      input_name    = string
      s3_uri        = string # Use "param:ParameterName" to reference a pipeline parameter
      local_path    = string
      s3_data_type  = optional(string, "S3Prefix")
      s3_input_mode = optional(string, "File")
    })), [])
    outputs = optional(list(object({
      output_name    = string
      s3_uri         = string # Use "param:ParameterName" to reference a pipeline parameter
      local_path     = string
      s3_upload_mode = optional(string, "EndOfJob")
    })), [])
  }))
  default = []
}

variable "condition_steps" {
  description = "List of condition step configurations"
  type = list(object({
    name       = string
    depends_on = optional(list(string), [])
    conditions = list(object({
      type        = string # e.g. "Equals", "GreaterThan", "GreaterThanOrEqualTo"
      left_value  = string # Use "param:ParameterName" or literal
      right_value = string
    }))
    if_steps   = optional(list(string), []) # Names of processing steps to run if true
    else_steps = optional(list(string), []) # Names of processing steps to run if false
  }))
  default = []
}

variable "schedule_expression" {
  description = "The cron expression to schedule the pipeline execution (e.g., 'cron(0 12 * * ? *)'). If null, no schedule is created."
  type        = string
  default     = null
}
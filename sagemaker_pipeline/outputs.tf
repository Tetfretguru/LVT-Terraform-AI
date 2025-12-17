output "name" {
  description = "The name of the SageMaker Pipeline"
  value       = aws_sagemaker_pipeline.sagemaker_pipeline.name
}

output "arn" {
  description = "The ARN of the SageMaker Pipeline"
  value       = aws_sagemaker_pipeline.sagemaker_pipeline.arn
}

output "pipeline_definition" {
  description = "The JSON pipeline definition of the SageMaker Pipeline"
  value       = aws_sagemaker_pipeline.sagemaker_pipeline.pipeline_definition
}

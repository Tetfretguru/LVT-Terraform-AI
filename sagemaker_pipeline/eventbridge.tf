resource "aws_cloudwatch_event_rule" "pipeline_schedule" {
  count = var.schedule_expression != null ? 1 : 0

  name        = "${var.pipeline_name}-schedule"
  description = "Schedule for SageMaker Pipeline ${var.pipeline_name}"
  schedule_expression = var.schedule_expression
}

resource "aws_iam_role" "eventbridge_role" {
  count = var.schedule_expression != null ? 1 : 0

  name = "${var.pipeline_name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_policy" {
  count = var.schedule_expression != null ? 1 : 0

  name        = "${var.pipeline_name}-eventbridge-policy"
  description = "Policy for EventBridge to start SageMaker Pipeline execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sagemaker:StartPipelineExecution"
        ]
        Effect   = "Allow"
        Resource = aws_sagemaker_pipeline.sagemaker_pipeline.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_policy_attachment" {
  count = var.schedule_expression != null ? 1 : 0

  role       = aws_iam_role.eventbridge_role[0].name
  policy_arn = aws_iam_policy.eventbridge_policy[0].arn
}

resource "aws_cloudwatch_event_target" "pipeline_target" {
  count = var.schedule_expression != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.pipeline_schedule[0].name
  target_id = "SageMakerPipelineTarget"
  arn       = aws_sagemaker_pipeline.sagemaker_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_role[0].arn
}

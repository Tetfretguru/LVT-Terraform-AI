variables {
    pipeline_name = "test-pipeline-validation"
    role_arn      = "arn:aws:iam::123456789012:role/service-role/AmazonSageMaker-ExecutionRole"
    
    processing_steps = [
        {
            name           = "TestStep"
            image_uri      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/image:latest"
            entrypoint     = ["python", "script.py"]
            arguments      = ["--test-arg", "value"]
            instance_type  = "ml.m5.xlarge"
        }
    ]
}

run "valid_input_plan" {
    command = plan

    assert {
        condition     = aws_sagemaker_pipeline.sagemaker_pipeline.pipeline_name == var.pipeline_name
        error_message = "Pipeline name does not match input"
    }

    assert {
        condition     = aws_sagemaker_pipeline.sagemaker_pipeline.role_arn == var.role_arn
        error_message = "Role ARN does not match input"
    }
}

run "schedule_creation_plan" {
    command = plan

    variables {
        schedule_expression = "cron(0 12 * * ? *)"
    }

    assert {
        condition     = length(aws_cloudwatch_event_rule.pipeline_schedule) == 1
        error_message = "EventBridge rule was not created when cron expression was provided"
    }

    assert {
        condition     = aws_cloudwatch_event_rule.pipeline_schedule[0].schedule_expression == "cron(0 12 * * ? *)"
        error_message = "Cron expression does not match"
    }
}

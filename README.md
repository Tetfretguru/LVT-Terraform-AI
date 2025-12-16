# LVT-Terraform-AI

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)

**Open Source Terraform Modules for AI Infrastructure**

Welcome to **LVT-Terraform-AI**! This project aims to provide a comprehensive collection of high-quality, reusable Terraform modules designed specifically for Artificial Intelligence and Machine Learning workflows on AWS.

Our goal is to simplify the deployment of complex AI infrastructure, allowing data scientists and ML engineers to focus on their models rather than the underlying plumbing.

---

## Available Modules

### [SageMaker Pipeline](./sagemaker_pipeline)

A powerful module to define and deploy **Amazon SageMaker Pipelines** using Terraform.

*   **Dynamic Steps**: Define processing steps, training steps, and more via configuration.
*   **Conditional Logic**: Support for `ConditionStep` to create branching workflows (If/Else).
*   **Pipeline Parameters**: Inject runtime values (S3 paths, instance types, etc.).
*   **Retry Policies**: Built-in support for robust error handling and retries.
*   **Dependency Management**: Easily define execution order with `depends_on`.

---

## Roadmap & Future Development

We are just getting started! Here is what we are planning to add in the near future:

*   [ ] **SageMaker Model Registry**: Modules for managing model versions and approval workflows.
*   [ ] **SageMaker Endpoints**: Simplified deployment for real-time and serverless inference endpoints.
*   [ ] **Bedrock Integration**: Modules for managing Generative AI models and knowledge bases.
*   [ ] **Glue & EMR**: Better integration for data preprocessing pipelines.
*   [ ] **Step Functions**: Orchestration patterns for hybrid workflows.

---

For detailed documentation, please refer to the `README.md` inside each module's directory.

---

## Contributing

We welcome contributions! Whether it's fixing a bug, adding a new feature, or creating a whole new module, your help is appreciated.

1.  Fork the repository.
2.  Create a feature branch.
3.  Commit your changes.
4.  Open a Pull Request.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

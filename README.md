# Insight-Agent Service on GCP

This project provides a production-ready environment for the "Insight-Agent" Python application on Google Cloud Platform. The infrastructure is provisioned using Terraform, and deployments are automated with a CI/CD pipeline using GitHub Actions.

## Architecture Overview

The architecture is designed to be serverless, scalable, and secure.

*   **Application**: A Python FastAPI application containerized with Docker.
*   **Container Registry**: [Google Artifact Registry](https://cloud.google.com/artifact-registry) stores the Docker container images.
*   **Compute**: [Google Cloud Run](https://cloud.google.com/run) runs the container in a serverless environment.
*   **CI/CD**: [GitHub Actions](https://github.com/features/actions) automates the build, push, and deployment of the application.
*   **Infrastructure as Code**: [Terraform](https://www.terraform.io/) defines and manages all GCP resources.

## Design Decisions

*   **Why Cloud Run?**: We chose Cloud Run for its serverless nature, which means we only pay for the compute we use. It scales automatically based on traffic, including scaling to zero, which is perfect for an MVP.
*   **Security**:
    *   The Cloud Run service is configured for **internal-only ingress**, meaning it is not accessible from the public internet. This is a crucial security measure for a backend service.
    *   A dedicated, least-privilege IAM service account is used for the Cloud Run service.
    *   We use Workload Identity Federation for our CI/CD pipeline, which avoids the need for long-lived service account keys.
*   **CI/CD Automation**: The pipeline in GitHub Actions ensures that every push to the `main` branch is automatically built, tested (optional step), and deployed. This leads to faster and more reliable deployments.
*   **Infrastructure as Code (IaC)**: Using Terraform allows us to version control our infrastructure, making it reproducible and easy to manage.

## Setup and Deployment

### Prerequisites

1.  [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and initialized.
2.  [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed.
3.  A GCP project with billing enabled.
4.  A GitHub repository.

### Initial Setup

1.  **Clone the repository.**
2.  **Set up GCP authentication for Terraform on your local machine:**
    ```bash
    gcloud auth application-default login
    ```
3.  **Set up Workload Identity Federation between GitHub Actions and GCP** by following the official Google Cloud documentation or a trusted guide. This involves creating a Workload Identity Pool, a Provider, a service account for GitHub Actions, and granting it the necessary permissions.
4.  **Add the required secrets to your GitHub repository:**
    *   `GCP_PROJECT_ID`: Your Google Cloud project ID.
    *   `GCP_SA_EMAIL`: The email of the service account for GitHub Actions.
    *   `GCP_WORKLOAD_IDENTITY_PROVIDER`: The full resource name of your Workload Identity Provider.

### First Manual Deployment (Optional)

To deploy the infrastructure for the first time manually:

1.  Navigate to the `terraform` directory: `cd terraform`
2.  Create a `terraform.tfvars` file with your project ID:
    ```
    gcp_project_id = "your-gcp-project-id"
    ```
3.  Initialize Terraform:
    ```bash
    terraform init
    ```
4.  Apply the Terraform configuration:
    ```bash
    terraform apply
    ```

### Automated Deployment

After the initial setup, every `git push` to the `main` branch will trigger the GitHub Actions workflow to:
1.  Build the Docker image.
2.  Push the image to Google Artifact Registry.
3.  Apply the Terraform configuration to deploy the new image to Cloud Run.
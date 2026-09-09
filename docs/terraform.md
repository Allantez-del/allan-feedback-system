# Terraform Documentation

## Overview

The Allan Feedback System uses Terraform to define and manage its AWS infrastructure as code.

Terraform makes the deployment reproducible and documents the relationships between the serverless application resources. The current configuration is designed for the development environment and deploys into the configured AWS region.

---

# Terraform Structure

Terraform configuration is stored in the `terraform/` directory.

## `providers.tf`

`providers.tf` configures the AWS provider and the deployment region used by the project.

The AWS region is supplied through `var.aws_region`.

## `main.tf`

`main.tf` defines the implemented AWS infrastructure, resource configuration, routes, permissions, monitoring, and authentication resources.

## `variables.tf`

`variables.tf` defines the configurable project variables:

- `aws_region` - AWS region used to deploy the system
- `project_name` - project name used for resource tags
- `environment` - deployment environment used for resource tags

The current default values are:

```text
aws_region   = eu-central-1
project_name = Allan Feedback System
environment  = dev
```

## `outputs.tf`

`outputs.tf` exposes the deployment values needed after provisioning:

- `api_endpoint`
- `cognito_user_pool_id`
- `cognito_app_client_id`

## `.terraform.lock.hcl`

`.terraform.lock.hcl` records the selected Terraform provider versions and is tracked so provider selection remains reproducible.

---

# Implemented Infrastructure

The current Terraform configuration includes the following resources.

## DynamoDB

Terraform creates the `allan-feedback` DynamoDB table for feedback records.

The table uses the `feedbackId` partition key and on-demand billing with `PAY_PER_REQUEST`. Point-in-Time Recovery is enabled.

## IAM Role and Policy

Terraform creates the Lambda execution role and its policy.

The policy grants the Lambda function the DynamoDB permissions required by the application:

```text
dynamodb:PutItem
dynamodb:Scan
```

The role also uses the AWS managed basic execution policy for CloudWatch logging.

## CloudWatch Log Group

Terraform creates the Lambda log group:

```text
/aws/lambda/allan-feedback-handler
```

The log retention period is 14 days.

## Lambda Function

Terraform deploys the `allan-feedback-handler` Lambda function using Python 3.13.

The Lambda function validates POST input, writes feedback to DynamoDB, retrieves feedback for GET requests, and handles unexpected errors with generic client responses.

The deployment package is:

```text
lambda/feedback_handler.zip
```

The ZIP is tracked because Terraform deploys it directly through the Lambda `filename` configuration and calculates its source code hash.

## API Gateway HTTP API

Terraform creates the API Gateway HTTP API used to expose the feedback service.

CORS is configured for the current development setup, which allows requests from all origins.

## API Routes

The configuration includes two routes:

- `POST /feedback` - public customer feedback submission route
- `GET /feedback` - protected staff feedback retrieval route

The POST route intentionally remains public. The GET route requires a valid Cognito JWT.

## JWT Authorizer

Terraform creates a JWT authorizer for the GET route.

The authorizer uses the Cognito User Pool issuer and app client audience to validate bearer tokens before API Gateway invokes Lambda.

## Cognito User Pool and App Client

Terraform creates:

- a Cognito User Pool for staff authentication
- a Cognito User Pool App Client for staff login and token issuance

The app client is configured without a client secret for public client access.

## Lambda Permission

Terraform creates the Lambda permission allowing API Gateway to invoke the feedback Lambda function.

The permission is scoped to API Gateway invocation of the configured API routes.

## CloudWatch Lambda Error Alarm

Terraform creates the Lambda error alarm:

```text
allan-feedback-lambda-errors
```

The alarm monitors the AWS Lambda `Errors` metric with a five-minute period and enters the alarm state when the error count is greater than zero during one evaluation period.

## CloudWatch Dashboard

Terraform creates the dashboard:

```text
allan-feedback-dashboard
```

The dashboard monitors:

- Lambda invocations
- Lambda errors
- Lambda throttles
- Lambda duration
- API Gateway request count
- API Gateway 4xx responses
- API Gateway 5xx responses
- DynamoDB consumed read capacity
- DynamoDB consumed write capacity
- DynamoDB read throttle events
- DynamoDB write throttle events

---

# Terraform Dependencies

Terraform infers dependencies through resource references.

For example, the Lambda function references the IAM role and DynamoDB table, API Gateway routes reference the Lambda integration, the JWT authorizer references Cognito resources, and the dashboard references Lambda, API Gateway, and DynamoDB resources.

These references allow Terraform to determine creation and update ordering without manually listing every dependency. Explicit dependencies are used where required to ensure the Lambda deployment prerequisites are available.

---

# Terraform State

Terraform state is currently stored locally for this development project.

Local state files and Terraform working directories are ignored by Git and are not part of the source-controlled application.

A production deployment should use a secured remote backend with appropriate encryption, access control, state locking, and backup procedures. A remote backend is not currently implemented in this project.

---

# Deployment Commands

Run the following commands from the `terraform/` directory.

## Initialize Terraform

```text
terraform init
```

## Format Terraform

```text
terraform fmt -recursive
```

## Validate the Configuration

```text
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

## Review the Plan

```text
terraform plan
```

After the Week 4 variable refactor, the verified plan result was:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that replacing repeated region and tag literals with Terraform variables did not introduce infrastructure changes.

## Apply the Configuration

```text
terraform apply
```

Review the proposed changes and confirm the deployment when prompted.

## View Outputs

```text
terraform output
```

Individual outputs can also be requested, for example:

```text
terraform output api_endpoint
terraform output cognito_user_pool_id
terraform output cognito_app_client_id
```

## Destroy the Development Infrastructure

```text
terraform destroy
```

Review the resources that will be deleted before confirming. Destroying the environment can delete the DynamoDB table and stored feedback data.

---

# Lambda ZIP Deployment

Terraform deploys `lambda/feedback_handler.zip` directly. When `lambda/feedback_handler.py` changes, rebuild the ZIP before running Terraform plan or apply.

From the project root in PowerShell:

```powershell
Compress-Archive `
  -Path .\lambda\feedback_handler.py `
  -DestinationPath .\lambda\feedback_handler.zip `
  -Force
```

Then run:

```text
cd terraform
terraform plan
terraform apply
```

The ZIP remains tracked because it is the deployment artifact referenced directly by Terraform.

---

# Current Scope

This documentation describes the infrastructure currently implemented in Terraform. It does not claim that a remote backend, CI/CD pipeline, or other future production capability has been deployed.

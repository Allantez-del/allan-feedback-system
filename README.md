Allan Feedback System

A serverless feedback collection API built on AWS Lambda, API Gateway, and DynamoDB. This system validates and stores customer feedback across multiple categories with a simple REST API.



Table of Contents

Prerequisites
Project Structure
Installation & Setup
Commands
Deployment
API Usage
Test Cases
Troubleshooting
Verification Checklist



Prerequisites

Required Software

Python 3.13 or later
Terraform 1.0 or later (for infrastructure deployment)
AWS CLI v2 (for AWS account interaction)
Git 2.0 or later

AWS Account & Credentials

An active AWS account with programmatic access enabled
AWS credentials configured locally:
  aws configure
  Provide your AWS Access Key ID, Secret Access Key, and region (default: eu-central-1)

Environment Setup

Before deployment, ensure the following:

AWS Region: This project is configured for eu-central-1. To use a different region, update terraform/providers.tf.
Terraform State: Terraform will create a local state file in terraform/terraform.tfstate. For production, configure remote state (e.g., S3 backend).
IAM Permissions: Your AWS user must have permissions for:
DynamoDB (CreateTable, PutItem, DescribeTable)
Lambda (CreateFunction, UpdateFunctionCode, InvokeFunction)
API Gateway (CreateApi, CreateRoute, CreateIntegration, CreateStage)
IAM (CreateRole, AttachRolePolicy, PutRolePolicy)

Optional Tools

curl or Postman for testing the API manually
Python virtual environment (for local testing)
AWS SAM CLI (for local Lambda testing, optional)



Project Structure

.
├── README.md                      # This file
├── lambda/
│   ├── feedback_handler.py       # Lambda function source code
│   └── feedback_handler.zip      # Compiled function package
├── terraform/
│   ├── main.tf                   # Core infrastructure (Lambda, API Gateway, DynamoDB)
│   ├── providers.tf              # AWS provider configuration
│   ├── outputs.tf                # Terraform output values (API endpoint)
│   └── terraform.tfstate         # Terraform state file (auto-generated)
├── docs/
│   └── api/                      # API documentation (future)
├── test-event.json               # Sample valid feedback payload for testing
├── invalid-event.json            # Sample invalid feedback payload for testing
├── response.json                 # Example successful API response
└── invalid-response.json         # Example error API response

Key Components

lambda/feedback_handler.py: AWS Lambda handler that validates feedback payloads and stores them in DynamoDB
terraform/main.tf: Defines DynamoDB table, Lambda function, API Gateway HTTP API, IAM roles, and integrations
terraform/outputs.tf: Outputs the API endpoint URL for client testing



Installation & Setup

Step 1: Clone the Repository

git clone https://github.com/Allantez-del/allan-feedback-system.git
cd allan-feedback-system

Step 2: Verify Prerequisites

# Check Python version
python --version

# Check Terraform version
terraform version

# Check AWS CLI configuration
aws sts get-caller-identity

Expected output from aws sts get-caller-identity:
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}

Step 3: Prepare the Lambda Package

The Lambda function is pre-packaged in lambda/feedback_handler.zip. If you need to rebuild it after code changes:

cd lambda
pip install -r requirements.txt -t .  # (Note: create requirements.txt if it doesn't exist)
zip -r feedback_handler.zip feedback_handler.py
cd ..

For the current setup, boto3 is available in the Lambda runtime, so no additional dependencies are needed.

Step 4: Initialize Terraform

cd terraform
terraform init

This downloads AWS provider plugins and prepares the Terraform working directory.



Commands

Build & Package

# Rebuild the Lambda function package (if code changes were made)
cd lambda
zip -r feedback_handler.zip feedback_handler.py
cd ..

Deployment

cd terraform

# Plan the deployment (shows what will be created/modified)
terraform plan

# Apply the deployment (creates infrastructure)
terraform apply

# Output the API endpoint
terraform output api_endpoint

Testing

# Test the API with a valid feedback submission
curl -X POST <API_ENDPOINT>/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Jane Doe",
    "email": "jane@example.com",
    "rating": 5,
    "category": "service",
    "message": "The customer support was very helpful."
  }'

# Test with an invalid category (should fail)
curl -X POST <API_ENDPOINT>/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "invalid_category",
    "message": "This should fail."
  }'

Cleanup

cd terraform

# Destroy all infrastructure (WARNING: deletes the DynamoDB table and its data)
terraform destroy

# Confirm the destruction
# Type 'yes' when prompted



Deployment

Initial Deployment

Plan: Review what will be created
  cd terraform
   terraform plan

Apply: Deploy infrastructure to AWS
   terraform apply
   Confirm with yes when prompted. Terraform will:
Create a DynamoDB table named allan-feedback
Create a Lambda function named allan-feedback-handler
Create an API Gateway HTTP API named allan-feedback-api
Set up IAM roles and policies
Output the API endpoint URL

Verify: Note the API endpoint from the output:
  Outputs:

   api_endpoint = "https://xxxxxxx.eu-central-1.amazonaws.com"

Updating Code After Changes

If you modify lambda/feedback_handler.py:

Rebuild the zip file:
  cd lambda
   zip -r feedback_handler.zip feedback_handler.py
   cd ..

Redeploy:
  cd terraform
   terraform apply

Production Considerations

For production deployments:

State Management: Configure remote Terraform state (S3 + DynamoDB locking)
Point-in-Time Recovery: Already enabled in main.tf for DynamoDB
Monitoring: Add CloudWatch alarms and metrics
Versioning: Tag deployments with git tag and terraform workspace
Rollback: Keep previous state files; use terraform state commands to roll back



API Usage

Endpoint

POST <API_ENDPOINT>/feedback

Request Format

Headers:
Content-Type: application/json

Body (JSON):
{
  "rating": 5,
  "category": "service",
  "message": "The customer support was very helpful.",
  "customerName": "Jane Doe",
  "email": "jane@example.com"
}

Field Specifications

Field
Type
Required
Notes
rating
Integer
Yes
Must be 1–5 inclusive
category
String
Yes
One of: service, product, delivery, website, complaint, suggestion, other
message
String
Yes
Non-empty string; leading/trailing whitespace is trimmed
customerName
String
No
If provided, is trimmed of whitespace
email
String
No
If provided, is trimmed of whitespace

Response Codes

Code
Meaning
Example Response
201
Feedback submitted successfully
{"message": "Feedback submitted successfully.", "feedbackId": "uuid"}
400
Invalid request (validation error)
{"error": "rating must be an integer from 1 to 5"}
500
Server error
{"error": "Internal server error"}

Success Response (201)

{
  "message": "Feedback submitted successfully.",
  "feedbackId": "e4836d42-b4bb-449e-a48b-2d96f4924c4d"
}

The feedbackId is a UUID that uniquely identifies the feedback submission and is stored in DynamoDB with a timestamp.



Test Cases

Happy Path: Valid Feedback Submission

Objective: Verify that valid feedback is accepted and stored.

Request:
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Jane Doe",
    "email": "jane@example.com",
    "rating": 5,
    "category": "service",
    "message": "The customer support was very helpful."
  }'

Expected Response (201):
{
  "message": "Feedback submitted successfully.",
  "feedbackId": "e4836d42-b4bb-449e-a48b-2d96f4924c4d"
}

Verification: Log into AWS Console → DynamoDB → Tables → allan-feedback → Items. You should see a new item with the submitted feedback.



Validation Error: Invalid Rating

Objective: Verify that invalid ratings are rejected.

Test Case 1: Rating out of range (too high)
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 10,
    "category": "service",
    "message": "Feedback message."
  }'

Expected Response (400):
{
  "error": "rating must be an integer from 1 to 5"
}

Test Case 2: Rating is not an integer
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": "5",
    "category": "service",
    "message": "Feedback message."
  }'

Expected Response (400):
{
  "error": "rating must be an integer from 1 to 5"
}

Test Case 3: Rating missing
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "category": "service",
    "message": "Feedback message."
  }'

Expected Response (400):
{
  "error": "rating must be an integer from 1 to 5"
}



Validation Error: Invalid Category

Objective: Verify that invalid categories are rejected.

Request:
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "INVALID",
    "message": "Feedback message."
  }'

Expected Response (400):
{
  "error": "Invalid category"
}

Valid categories: service, product, delivery, website, complaint, suggestion, other



Validation Error: Empty or Missing Message

Objective: Verify that empty messages are rejected.

Test Case 1: Message is empty string
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "service",
    "message": ""
  }'

Expected Response (400):
{
  "error": "message is required"}

Test Case 2: Message is whitespace only
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "service",
    "message": "   "
  }'

Expected Response (400):
{
  "error": "message is required"}

Test Case 3: Message is not a string
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "service",
    "message": 123
  }'

Expected Response (400):
{
  "error": "message is required"}



Validation Error: Invalid JSON

Objective: Verify that malformed JSON is rejected.

Request:
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{invalid json}'

Expected Response (400):
{
  "error": "Invalid JSON body"}



Edge Case: Optional Fields

Objective: Verify that optional fields (customerName, email) work correctly.

Test Case 1: All optional fields omitted
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "service",
    "message": "Feedback without optional fields."
  }'

Expected Response (201):
{
  "message": "Feedback submitted successfully.",
  "feedbackId": "uuid"
}

Verification: The DynamoDB item will not have customerName or email fields.

Test Case 2: Only customerName provided
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 3,
    "category": "product",
    "message": "Good product.",
    "customerName": "John Smith"
  }'

Expected Response (201):
{
  "message": "Feedback submitted successfully.",
  "feedbackId": "uuid"
}

Verification: The item will have customerName but no email.

Test Case 3: Whitespace trimming
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 4,
    "category": "delivery",
    "message": "  Message with spaces.  ",
    "customerName": "  Jane Doe  ",
    "email": "  jane@example.com  "
  }'

Expected Response (201):
{
  "message": "Feedback submitted successfully.",
  "feedbackId": "uuid"
}

Verification: In DynamoDB, all strings are trimmed (no leading/trailing spaces).



Edge Case: Special Characters in Message

Objective: Verify that special characters and quotes are handled correctly.

Request:
curl -X POST https://xxxxxxx.eu-central-1.amazonaws.com/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "suggestion",
    "message": "I love your service! It'\''s amazing. Price: $99.99. Unicode: 你好 🚀"
  }'

Expected Response (201):
{
  "message": "Feedback submitted successfully.",
  "feedbackId": "uuid"
}



Troubleshooting

Issue: aws configure not working or credentials not found

Symptom: Error: The AWS Access Key ID and Secret Access Key are required.

Solution:
Run aws configure and provide your credentials
Verify with aws sts get-caller-identity
Check credentials file at ~/.aws/credentials (Linux/Mac) or %USERPROFILE%\.aws\credentials (Windows)



Issue: Terraform init fails with provider errors

Symptom: Error: Failed to query available provider packages

Solution:
Ensure you have internet connectivity
Update Terraform: terraform version and download latest from terraform.io
Remove .terraform and terraform.lock.hcl, then retry terraform init



Issue: Terraform apply fails with permission errors

Symptom: Error: creating DynamoDB Table: AccessDenied

Solution:
Verify IAM permissions: Check that your AWS user has DynamoDB, Lambda, and API Gateway permissions
Attach policy: AWSLambdaFullAccess, AmazonDynamoDBFullAccess, APIGatewayAdministrator (or custom least-privilege policy)
Check region: Ensure terraform/providers.tf specifies the correct region where you have permissions



Issue: API endpoint not created or deploy fails

Symptom: Error: creating AWS Lambda Function: ResourceConflictException or endpoint is null

Solution:
Check if resources already exist: aws lambda list-functions, aws dynamodb list-tables
If they exist but Terraform doesn't know about them, either:
Delete them in AWS Console and retry
Import them: terraform import aws_lambda_function.feedback <function-name>
Ensure lambda/feedback_handler.zip exists and is valid
Check Terraform plan before applying: terraform plan



Issue: Lambda function returns 500 error

Symptom: All requests return {"error": "Internal server error"}

Solution:
Check Lambda logs in AWS CloudWatch:
   aws logs tail /aws/lambda/allan-feedback-handler --follow
Common causes:
FEEDBACK_TABLE_NAME environment variable not set (check in Lambda console)
IAM role missing DynamoDB permissions
DynamoDB table doesn't exist or was deleted
Redeploy to fix: cd terraform && terraform apply



Issue: DynamoDB table not accepting writes

Symptom: 403 Forbidden or ValidationException when submitting feedback

Solution:
Verify table exists: aws dynamodb describe-table --table-name allan-feedback
Check Lambda IAM policy: Should allow dynamodb:PutItem on the feedback table
Verify Lambda environment variable: FEEDBACK_TABLE_NAME should be allan-feedback
Check billing mode: PAY_PER_REQUEST means no provisioned capacity limits



Issue: Lambda deployment package is outdated

Symptom: Code changes don't appear when testing the API

Solution:
Rebuild the zip: cd lambda && zip -r feedback_handler.zip feedback_handler.py
Redeploy: cd terraform && terraform apply
Verify in AWS Lambda console → Code → Last modified timestamp



Issue: CORS errors when calling from browser

Symptom: Cross-Origin Request Blocked in browser console

Solution:
The API Gateway currently has no CORS configuration. To enable CORS:
In terraform/main.tf, add CORS configuration to aws_apigatewayv2_api:
  cors_configuration {
     allow_origins     = ["*"]
     allow_methods     = ["POST"]
     allow_headers     = ["content-type"]
     max_age           = 300
   }
Redeploy: terraform apply
For production, replace "*" with specific allowed origins



Verification Checklist

Use this checklist to confirm everything is working correctly:

Pre-Deployment Checklist

AWS credentials are configured (aws sts get-caller-identity shows your account)
Terraform is installed and version is 1.0+
Python 3.13+ is available
Git repository is cloned and current branch is main
lambda/feedback_handler.zip exists and is not empty
terraform/ directory contains main.tf, providers.tf, and outputs.tf

Deployment Checklist

Run terraform init successfully (.terraform directory created)
Run terraform plan shows expected resources (DynamoDB table, Lambda, API Gateway)
Run terraform apply completes without errors
Note the API endpoint from terraform output api_endpoint
AWS Console shows new resources:
DynamoDB table: allan-feedback
Lambda function: allan-feedback-handler
API Gateway API: allan-feedback-api

API Testing Checklist

Happy Path: Submit valid feedback and receive 201 response with feedbackId
Invalid Rating: Submit rating outside 1–5 range, receive 400 error
Invalid Category: Submit unknown category, receive 400 error
Empty Message: Submit empty message, receive 400 error
Invalid JSON: Submit malformed JSON, receive 400 error
Optional Fields: Submit feedback without customerName and email, still works
Whitespace Trimming: Submit fields with leading/trailing spaces, verified in DynamoDB
Special Characters: Submit message with Unicode and symbols, stored correctly

DynamoDB Verification

Open AWS Console → DynamoDB → Tables → allan-feedback
Verify table has items from your API tests
Check item structure: feedbackId (UUID), rating, category, message, submittedAt, optional customerName and email
Verify submittedAt is in ISO 8601 format (e.g., 2026-08-31T15:19:26.932+02:00)
Point-in-time recovery is enabled (check in table settings)

Cleanup Checklist (when destroying)

Back up any important feedback data if needed
Run terraform destroy and confirm with yes
Verify in AWS Console that resources are deleted:
DynamoDB table allan-feedback gone
Lambda function allan-feedback-handler gone
API Gateway allan-feedback-api gone
IAM role allan-feedback-lambda-role gone



Next Steps

Monitoring: Add CloudWatch alarms for Lambda errors and DynamoDB throttling
Authentication: Implement API key or OAuth authentication
Feedback Retrieval: Add GET endpoints to retrieve feedback (with sorting/filtering)
Batch Operations: Add support for bulk feedback submission
Notifications: Send confirmation emails or Slack notifications on feedback submission
Analytics: Generate reports on feedback trends by category and rating
Multi-Region: Replicate infrastructure to other AWS regions for high availability



Support

For issues or questions:
Check the Troubleshooting section above
Review AWS CloudWatch logs: aws logs tail /aws/lambda/allan-feedback-handler
Check Terraform output: terraform output -json for detailed resource info
Review the source code: lambda/feedback_handler.py



License

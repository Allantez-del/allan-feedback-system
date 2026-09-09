# AWS Well-Architected Review

## Project Overview

The Allan Feedback System is a serverless customer feedback application deployed in AWS.

The architecture uses:

- Amazon API Gateway HTTP API
- AWS Lambda
- Amazon DynamoDB
- Amazon Cognito
- AWS Identity and Access Management (IAM)
- Amazon CloudWatch
- Terraform

The system separates public feedback submission from protected staff retrieval.

---

# 1. Security

## Current Design

Security controls are applied at several layers.

### API Access

`POST /feedback` is intentionally public so customers can submit feedback without creating an account.

`GET /feedback` is protected by an Amazon Cognito JWT authorizer.

Requests to the protected route must provide a valid JWT token through the HTTP Authorization header.

Unauthenticated requests are rejected by API Gateway before reaching Lambda.

### IAM Least Privilege

The Lambda execution role is limited to the DynamoDB permissions required by the application:

- `dynamodb:PutItem`
- `dynamodb:Scan`

The permissions are restricted to the `allan-feedback` DynamoDB table.

The Lambda function also uses the AWS managed basic execution policy for CloudWatch logging.

### Data Protection

Communication between clients and API Gateway uses HTTPS.

DynamoDB provides encryption at rest.

Clients do not receive direct access to the DynamoDB table.

Unexpected server errors return generic responses rather than exposing internal exception details.

### Input Validation

Lambda validates:

- rating type and range
- feedback category
- message presence
- message length
- optional string fields

This reduces invalid or malformed data before it reaches DynamoDB.

## Security Limitations and Improvements

The current development environment allows CORS requests from all origins.

For production, the API should restrict CORS to the trusted frontend domain.

The public POST endpoint could also be protected against abuse using controls such as:

- API throttling
- AWS WAF
- request rate limits
- CAPTCHA or bot protection where appropriate

Terraform state is currently stored locally and should use a secured remote backend in a production environment.

---

# 2. Reliability

## Current Design

The application uses managed AWS serverless services.

API Gateway, Lambda and DynamoDB remove the need to manage application servers manually.

DynamoDB Point-in-Time Recovery is enabled.

This provides recovery capability if table data is accidentally modified or deleted.

The Lambda function includes controlled error handling and returns appropriate HTTP responses.

CloudWatch Logs provide technical information for troubleshooting failures.

## Reliability Benefits

There are no EC2 instances that require manual patching, rebooting or replacement.

The managed architecture reduces the number of infrastructure components that can fail because of operating-system or server-management problems.

DynamoDB is designed as a highly available managed database service.

## Reliability Limitations and Improvements

The application currently has no separate backup export process in addition to Point-in-Time Recovery.

For a larger production system, additional recovery procedures should be documented and tested.

The application is synchronous:

Client -> API Gateway -> Lambda -> DynamoDB

If DynamoDB is temporarily unavailable, the current request can fail.

For workloads requiring guaranteed asynchronous processing, an architecture using Amazon SQS between the API and processing Lambda could be considered.

This is unnecessary for the current project workload but could improve resilience for a larger system.

---

# 3. Performance Efficiency

## Current Design

The system uses serverless services that allocate infrastructure on demand.

Lambda runs only when requests are received.

DynamoDB uses:

`PAY_PER_REQUEST`

This removes the need to pre-provision read and write capacity for the current workload.

API Gateway HTTP API provides a lightweight entry point to the Lambda function.

## Current Retrieval Pattern

Feedback retrieval currently uses:

`dynamodb:Scan`

The Lambda function limits retrieval to 20 records and sorts those records by `submittedAt`.

This is acceptable for the current demonstration dataset.

However, Scan becomes inefficient as the table grows because it reads across the table rather than targeting a specific access pattern.

## Performance Improvements

A production version should use:

- DynamoDB Query instead of Scan
- pagination
- an appropriate secondary index
- a data model designed around retrieval requirements

Lambda duration should continue to be monitored through CloudWatch.

Cold starts may affect individual requests, although this is acceptable for the current low-volume application.

---

# 4. Cost Optimization

## Serverless Cost Model

The architecture is designed to avoid continuously running infrastructure.

The main cost drivers are:

- API Gateway requests
- Lambda invocations
- Lambda execution duration
- DynamoDB read/write requests and storage
- CloudWatch logs and metrics
- Cognito usage

The application does not require continuously running EC2 instances or database servers.

This makes the architecture suitable for low or unpredictable traffic.

## DynamoDB

The table uses on-demand billing.

With `PAY_PER_REQUEST`, the project does not pay for permanently reserved read and write capacity.

This is useful for a feedback application where traffic may be irregular.

## Lambda

Lambda charges are based primarily on invocations and execution duration.

When no requests are being processed, there is no continuously running Lambda server.

## Cost Limitations

CloudWatch log volume can grow as traffic increases.

Long log retention periods and excessive logging can therefore increase cost.

The project currently retains the Lambda log group for 14 days, which limits unnecessary long-term log storage.

At higher and predictable DynamoDB workloads, alternative capacity strategies could be evaluated.

---

# 5. Scalability

## Low Traffic

At approximately 100 submissions per day, the architecture is significantly below the capacity of the managed AWS services used.

The serverless model remains cost-efficient because infrastructure does not need to be permanently provisioned for peak load.

## Higher Traffic

The architecture can also support much larger request volumes because API Gateway, Lambda and DynamoDB are managed scalable services.

At 100,000 submissions per day, the average request rate is still relatively modest, although real traffic may arrive in bursts rather than evenly throughout the day.

The most important concern would therefore be burst traffic, service quotas and application access patterns rather than the daily request count alone.

## Potential Bottlenecks

The most important scaling limitation in the current implementation is the GET operation using DynamoDB Scan.

As the number of feedback items grows, Scan becomes increasingly inefficient.

Additional scaling considerations include:

- Lambda concurrency
- API Gateway throttling and quotas
- DynamoDB access patterns
- CloudWatch log volume
- Cognito authentication traffic

## Future Scalable Design

A larger application should introduce:

- DynamoDB Query-based retrieval
- pagination
- suitable secondary indexes
- API throttling policies
- automated deployment pipelines
- additional alarms
- possible asynchronous processing for high write bursts

The current serverless architecture provides a strong foundation for these improvements without requiring a complete redesign.

---

# 6. Operational Excellence

## Infrastructure as Code

The AWS infrastructure is defined using Terraform.

The project includes Terraform resources for:

- DynamoDB
- Lambda
- IAM
- API Gateway
- Cognito
- CloudWatch

Deployment settings are defined using variables for:

- AWS region
- project name
- environment

Terraform outputs provide:

- API endpoint
- Cognito User Pool ID
- Cognito App Client ID

Terraform dependencies are defined through resource references and explicit Lambda dependencies where required.

## Monitoring

The CloudWatch dashboard monitors:

- Lambda invocations
- Lambda errors
- Lambda throttles
- Lambda duration
- API Gateway request count
- API Gateway 4xx responses
- API Gateway 5xx responses
- DynamoDB consumed capacity
- DynamoDB throttling events

A CloudWatch alarm is configured for Lambda errors.

## Operational Improvements

For production, the project could add:

- CI/CD deployment
- remote Terraform state
- automated testing
- API Gateway alarms
- DynamoDB throttling alarms
- structured application logging
- deployment environments such as dev, staging and production

---

# 7. Architecture Decision Summary

The project uses serverless AWS services instead of EC2 and a traditional relational database because the workload is small, request-driven and variable.

This reduces:

- server administration
- idle infrastructure
- patching requirements
- capacity planning
- initial operational complexity

Amazon DynamoDB was selected because the feedback data fits a simple key-based NoSQL model and does not currently require relational joins or complex transactions.

Amazon Cognito protects staff retrieval without requiring the application to implement its own authentication system.

Terraform makes the infrastructure reproducible and documents the relationship between AWS resources.

---

# 8. Overall Assessment

The current architecture is appropriate for the project requirements and low-to-medium traffic.

Its strongest characteristics are:

- serverless operation
- low idle cost
- managed scalability
- protected staff retrieval
- least-privilege DynamoDB access
- infrastructure as code
- monitoring and recovery capabilities

The main technical limitation is the DynamoDB Scan-based GET operation.

This is acceptable for the current demonstration workload, but Query-based access and pagination should be considered as the system grows.

# Architecture Decisions

This document records the major architectural choices in the implemented Allan Feedback System.

## Serverless Instead of EC2

**Problem being solved:** Provide a feedback API without operating continuously running application servers.

**Selected solution:** Use managed serverless services, primarily API Gateway, Lambda, and DynamoDB.

**Alternatives considered:** Amazon EC2 instances with a traditional application server.

**Reason for selection:** The project has demonstration-scale and potentially irregular traffic. Serverless services reduce operational administration and scale with requests.

**Trade-offs:** Usage-based services simplify operations and avoid idle server costs, but introduce service-specific limits, per-request pricing, and less control over the underlying runtime.

**Limitations:** This design does not provide the host-level control or continuously running environment that an EC2-based system would provide.

## DynamoDB Instead of RDS

**Problem being solved:** Persist feedback reliably without managing a relational database server.

**Selected solution:** Use the `allan-feedback` DynamoDB table with on-demand billing and Point-in-Time Recovery.

**Alternatives considered:** Amazon RDS and a relational schema.

**Reason for selection:** Feedback records have a straightforward item structure, and DynamoDB provides managed persistence and on-demand scaling for the current workload.

**Trade-offs:** DynamoDB avoids database server management and supports flexible request scaling, but access patterns must be designed around keys and indexes. On-demand pricing is convenient for irregular traffic but may cost more than provisioned capacity at consistently high predictable volume.

**Limitations:** The current GET implementation uses `Scan` with a 20-item limit. A larger production dataset should use `Query`, pagination, and suitable indexes.

## API Gateway as the API Entry Point

**Problem being solved:** Expose stable HTTP endpoints for customers and authorized staff.

**Selected solution:** Use an API Gateway HTTP API with `POST /feedback` and `GET /feedback` routes.

**Alternatives considered:** Exposing Lambda directly or placing the API behind a self-managed web server.

**Reason for selection:** API Gateway supplies the HTTP routing boundary, integrates with Lambda, and supports the JWT authorizer used by the protected route.

**Trade-offs:** The managed entry point reduces infrastructure work and supports request-based scaling, but adds service configuration and API Gateway request costs.

**Limitations:** The current development configuration permits broad CORS, and the project does not implement a custom API domain, WAF, or rate limiting.

## Lambda as Stateless Backend Compute

**Problem being solved:** Run validation and persistence logic without maintaining application servers.

**Selected solution:** Use a Python 3.13 AWS Lambda function as the backend handler.

**Alternatives considered:** A stateful application server on EC2 or another continuously running compute service.

**Reason for selection:** Lambda runs the request logic on demand, integrates directly with API Gateway and DynamoDB, and keeps the backend stateless. Feedback state remains in DynamoDB.

**Trade-offs:** Lambda reduces server administration and scales automatically, but execution limits, cold starts, and event-driven debugging patterns apply.

**Limitations:** The handler is intentionally small and does not implement background processing, long-running work, or a broader service layer.

## Cognito/JWT for Staff Retrieval

**Problem being solved:** Allow authorized staff to retrieve feedback while keeping customer submission easy to access.

**Selected solution:** Protect only `GET /feedback` with an API Gateway JWT authorizer backed by Amazon Cognito.

**Alternatives considered:** Making both routes public, requiring authentication for customer submission, or implementing custom authentication in Lambda.

**Reason for selection:** Staff retrieval needs an authentication boundary, while customers do not need accounts to submit feedback. API Gateway can reject invalid tokens before Lambda runs.

**Trade-offs:** Cognito provides managed authentication and JWT validation, but requires user-pool configuration and staff account administration.

**Limitations:** The current system demonstrates staff authentication but does not implement roles beyond the protected retrieval route or a frontend login experience.

## Direct Client-to-DynamoDB Access Rejected

**Problem being solved:** Prevent clients from bypassing validation and application security controls.

**Selected solution:** Route all database access through Lambda. Clients never receive direct DynamoDB permissions or credentials.

**Alternatives considered:** Giving customer or staff clients direct DynamoDB access through IAM or an identity pool.

**Reason for selection:** Lambda centralizes validation, controls the available operations, and prevents the API clients from accessing arbitrary table data.

**Trade-offs:** The extra backend hop adds an invocation and processing step, but provides a clear security and validation boundary.

**Limitations:** Lambda must remain available and correctly permissioned for every database operation.

## CloudWatch for Observability

**Problem being solved:** Provide operational visibility into request processing and failures.

**Selected solution:** Use CloudWatch Logs, a dashboard, and a Lambda error alarm.

**Alternatives considered:** Self-managed logging and monitoring infrastructure.

**Reason for selection:** CloudWatch integrates with Lambda, API Gateway, and DynamoDB and avoids operating a separate monitoring platform for this project.

**Trade-offs:** Managed integration reduces setup and maintenance, while CloudWatch costs and service-specific dashboards and alarm configuration remain.

**Limitations:** The current alarm focuses on Lambda errors. Production monitoring could require additional alarms, retention policies, and operational response procedures.

## Terraform for Infrastructure as Code

**Problem being solved:** Provision the AWS resources consistently and keep the infrastructure definition reviewable.

**Selected solution:** Manage the implemented AWS infrastructure with Terraform.

**Alternatives considered:** Manual AWS Console configuration or an alternative infrastructure provisioning tool.

**Reason for selection:** Terraform describes the API, Lambda, DynamoDB, IAM, Cognito, and CloudWatch resources declaratively and supports repeatable development deployments.

**Trade-offs:** Infrastructure changes become reproducible and reviewable, but Terraform state and provider configuration must be managed securely.

**Limitations:** Terraform state is local for development. A production setup should use secured remote state, state locking, and controlled CI/CD workflows.

## No Customer-Managed VPC

**Problem being solved:** Keep the demonstration architecture small while using managed AWS service endpoints.

**Selected solution:** Do not add a customer-managed VPC to the current implementation.

**Alternatives considered:** Running Lambda in a VPC with custom networking, subnets, route tables, and additional network controls.

**Reason for selection:** The current Lambda function accesses API Gateway, DynamoDB, Cognito, and CloudWatch through managed services, and the project does not require private application resources that demand custom networking.

**Trade-offs:** Omitting a VPC reduces networking complexity and operational cost, but provides fewer customer-controlled network isolation options.

**Limitations:** This decision is suitable for the current demonstration and should be reassessed if private resources, stricter network boundaries, or additional integrations are introduced.

## No S3 Frontend Hosting in the Current Implementation

**Problem being solved:** Focus the project on demonstrating the API and its backend controls.

**Selected solution:** Do not implement S3 frontend hosting. The current project exposes and tests the API directly.

**Alternatives considered:** Hosting a browser frontend in Amazon S3 and connecting it to the HTTP API.

**Reason for selection:** No frontend is required for the current API demonstration, so adding frontend hosting would expand the architecture beyond the implemented scope.

**Trade-offs:** The smaller system is simpler and cheaper to operate, but users do not receive a hosted browser interface.

**Limitations:** S3 frontend hosting remains optional future work and is not part of the current implementation.

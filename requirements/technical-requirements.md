# Technical Requirements

## Implemented Architecture

The system must be implemented using the following AWS services and infrastructure components:

- Amazon API Gateway HTTP API as the public API entry point.
- AWS Lambda running Python 3.13 for request handling, validation, and application logic.
- An Amazon DynamoDB table using on-demand billing for persistent feedback storage.
- An IAM Lambda execution role with permissions limited to the operations required by the application.
- Amazon Cognito and an API Gateway JWT authorizer for protected staff access.
- Amazon CloudWatch logs, a dashboard, and an alarm for operational visibility.
- DynamoDB Point-in-Time Recovery (PITR) for the feedback table.
- Terraform Infrastructure as Code for provisioning and managing the AWS resources.

## API Requirements

- The API must expose a public `POST /feedback` route for customer submissions.
- The API must expose a Cognito/JWT-protected `GET /feedback` route for authorized staff retrieval.
- The Lambda function must validate incoming feedback before storing it.
- The API must return safe, generic error responses for unexpected server-side failures and write technical details to CloudWatch logs.

## Access and Data Requirements

- Customers must not require staff authentication to submit feedback.
- Clients must not receive direct access to DynamoDB.
- Lambda access to DynamoDB must be restricted to the implemented feedback operations, including `PutItem` and `Scan`.
- The feedback table must use a generated feedback identifier as its partition key.

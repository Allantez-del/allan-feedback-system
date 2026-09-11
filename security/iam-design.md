# IAM Design

## Lambda Execution Role

The Lambda function uses the execution role `allan-feedback-lambda-role`.

Its trust relationship allows the AWS Lambda service principal `lambda.amazonaws.com` to assume the role. This lets Lambda obtain temporary credentials for the actions required while processing API requests.

## Logging Permissions

The role attaches the AWS managed policy `AWSLambdaBasicExecutionRole`. This supplies the standard permissions required for Lambda to write execution logs to Amazon CloudWatch Logs.

## DynamoDB Permissions

The role also has an inline DynamoDB policy containing only the application operations currently used by the handler:

- `dynamodb:PutItem` for customer feedback submission.
- `dynamodb:Scan` for authorized staff feedback retrieval.

The permissions are scoped to the ARN of the `allan-feedback` DynamoDB table. The application policy does not grant `dynamodb:*`, and it does not use `Resource: "*"` for access to the application table.

This is a least privilege design: the Lambda function receives only the DynamoDB actions and table resource needed by the implemented API behavior. Customers and staff clients never receive direct DynamoDB access or AWS credentials. They interact with the API, while Lambda performs the database operations server-side.

## Invocation Permission

API Gateway is allowed to invoke the Lambda function through the Terraform-managed `aws_lambda_permission` resource. The permission identifies API Gateway as the invoking principal and limits invocation to the API execution ARN pattern.

## API Authentication Boundaries

The API intentionally has separate access rules for its two routes:

- `GET /feedback` is protected by an Amazon Cognito JWT authorizer. Only requests with a valid staff authentication token reach the Lambda integration.
- `POST /feedback` remains public by design so customers can submit feedback without creating an account or receiving AWS credentials.

The public POST route does not provide direct database access; it exposes only the validated feedback submission operation.

## Current Limitations

The current IAM design is appropriate for the demonstration, but it has boundaries that should be reviewed before production use:

- The GET implementation uses `dynamodb:Scan`, which is broader than a query-oriented access pattern within the table and should be replaced with a suitable `Query` and index design as the dataset grows.
- The public POST route has no implemented WAF or rate-limiting controls for abuse protection.
- Development CORS is permissive and should be restricted to trusted origins for production.
- Terraform state is local for development; production deployments should use a secured remote backend and controlled deployment permissions.

These limitations do not change the core least privilege approach: clients remain separated from DynamoDB, and the Lambda role is restricted to the implemented table operations.

# Security Documentation

## Overview

The Allan Feedback System uses multiple AWS security controls to protect customer feedback while keeping the customer submission endpoint easy to access.

The security model separates public feedback submission from authenticated staff retrieval.

---

# 1. API Access Model

The API exposes two routes:

| Route | Access |
| --- | --- |
| POST /feedback | Public |
| GET /feedback | Cognito JWT authentication required |

The POST endpoint is intentionally public so customers do not need an account to submit feedback.

The GET endpoint is restricted to authenticated staff users.

---

# 2. Amazon Cognito Authentication

Amazon Cognito provides staff authentication.

API Gateway uses a JWT authorizer to validate the token before allowing access to:

```text
GET /feedback
```

A valid token must be supplied through the HTTP Authorization header:

```text
Authorization: Bearer <JWT_TOKEN>
```

Requests without a valid token are rejected by API Gateway with:

```text
401 Unauthorized
```

Authentication is enforced at the API Gateway layer before the request reaches Lambda.

The Cognito app client does not use a client secret because it is intended for public client authentication flows.

JWT tokens and passwords must never be stored in source control.

---

# 3. IAM Least Privilege

The Lambda execution role is limited to the AWS permissions required by the application.

The application currently requires:

```text
dynamodb:PutItem
dynamodb:Scan
```

`dynamodb:PutItem` is used to store customer feedback.

`dynamodb:Scan` is used to retrieve feedback for the protected GET route.

These permissions are scoped to the `allan-feedback` DynamoDB table rather than being granted across all DynamoDB resources.

The Lambda role also uses the AWS managed basic execution policy for writing logs to CloudWatch.

Clients do not receive direct IAM credentials or direct access to DynamoDB.

---

# 4. Data Protection

Client communication with API Gateway uses HTTPS.

DynamoDB provides encryption at rest for stored feedback data.

The API does not expose DynamoDB credentials or implementation details to clients.

Unexpected application and database failures return a generic response:

```text
500 Internal Server Error
```

Technical details are written to CloudWatch Logs for authorized operators rather than returned in the API response.

Terraform state is local in the development project and is excluded from source control. A production deployment should use an encrypted remote backend with access control and state locking.

---

# 5. Input Validation

The Lambda function validates feedback before writing it to DynamoDB.

Validation includes:

- rating must be an integer from 1 to 5
- category must be one of the supported categories
- message must be present and non-empty
- message must not exceed 2000 characters
- optional customerName must be a string
- optional email must be a string
- malformed JSON is rejected

Invalid requests return:

```text
400 Bad Request
```

Input validation reduces malformed data and prevents unexpected values from reaching the database layer.

---

# 6. CORS and Browser Access

The development API currently allows requests from all origins:

```text
allow_origins = ["*"]
```

This supports development and testing while no permanent frontend domain has been deployed.

For production, CORS should be restricted to the trusted frontend domain. Allowed methods and headers should also be limited to those required by the application.

CORS is not an authentication mechanism and must not be used as a replacement for Cognito authorization.

---

# 7. Logging and Monitoring

Amazon CloudWatch provides operational visibility for the API and Lambda function.

The Lambda log group is:

```text
/aws/lambda/allan-feedback-handler
```

Logs are retained for 14 days.

The CloudWatch dashboard monitors:

- Lambda invocations
- Lambda errors
- Lambda throttles
- Lambda duration
- API Gateway request count
- API Gateway 4xx responses
- API Gateway 5xx responses
- DynamoDB consumed capacity
- DynamoDB read and write throttle events

The configured Lambda error alarm is:

```text
allan-feedback-lambda-errors
```

Application errors are logged using a generic server-side message so that troubleshooting information is available to operators without disclosing AWS implementation details to clients.

---

# 8. Recovery and Availability

DynamoDB Point-in-Time Recovery is enabled for the feedback table.

Point-in-Time Recovery helps recover table data after accidental modification or deletion.

API Gateway, Lambda, DynamoDB and Cognito are managed AWS services, reducing the need to administer operating systems or application servers.

Recovery procedures should still be documented and tested before production use. Production environments should consider remote Terraform state, backup verification and a documented restore process.

---

# 9. Security Testing

The security model was tested through the deployed API and infrastructure configuration.

Tests included:

- GET without a JWT returned `401 Unauthorized`
- GET with a valid Cognito JWT returned successful feedback data
- POST remained publicly accessible
- invalid input returned `400 Bad Request`
- malformed JSON returned a generic validation error
- controlled DynamoDB failure returned a generic `500 Internal Server Error`
- CloudWatch recorded technical failure details without exposing them through the API
- Terraform configuration validated successfully

These tests confirm that public submission and protected retrieval remain separate security paths.

---

# Current Security Limitations

The project is a demonstration-scale development system and has the following security limitations:

- CORS allows all origins
- POST is public and does not include abuse protection
- AWS WAF is not configured
- API throttling and rate limits are not configured
- API Gateway and DynamoDB have no separate security alarms
- Terraform state uses a local development backend
- there is no CI/CD security scanning pipeline
- there is no cross-region disaster-recovery architecture
- GET uses DynamoDB Scan rather than a query-oriented access pattern

These limitations are documented so they can be addressed before a production launch.

---

# Production Hardening

Before production deployment, the system should restrict CORS, add API throttling and abuse controls, evaluate AWS WAF, use a secured remote Terraform backend, add security-focused alarms, review IAM policies regularly, test recovery procedures, and introduce automated dependency and infrastructure security scanning.

The current design provides a sound foundation for these production hardening improvements while preserving a public customer submission experience and protected staff retrieval.

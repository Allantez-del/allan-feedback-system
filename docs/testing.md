# Testing Documentation

## Overview

The Customer Feedback System was tested incrementally during development.

Testing covered:

- successful feedback submission
- input validation
- feedback retrieval
- authentication
- authorization
- controlled server-side failures
- Terraform configuration validation

The testing approach verified both normal operation and failure behavior.

---

# POST /feedback Testing

## Successful Submission

A valid feedback request was sent to:

`POST /feedback`

Expected result:

`201 Created`

The API returned a generated feedback ID and stored the record in DynamoDB.

---

# Validation Testing

The Lambda function was tested with invalid input.

Validation scenarios included:

- missing rating
- rating outside the range 1 to 5
- invalid rating type
- unsupported category
- missing message
- empty message
- message longer than 2000 characters
- invalid optional field types

Expected result:

`400 Bad Request`

These tests confirmed that invalid feedback is rejected before being stored in DynamoDB.

---

# GET /feedback Testing

The retrieval route was tested using:

`GET /feedback`

The route retrieves feedback from DynamoDB.

The current implementation returns up to 20 records and orders them by `submittedAt` with the newest records first.

---

# Authentication Testing

## Request Without JWT

A request was sent to:

`GET /feedback`

without a Cognito JWT token.

Expected result:

`401 Unauthorized`

The request was rejected by API Gateway before Lambda processing.

---

## Request With Valid JWT

A valid Cognito token was supplied in the Authorization header.

Expected result:

`200 OK`

The protected feedback data was returned successfully.

This confirmed that the JWT authorizer was correctly connected to the GET route.

---

# Public POST Verification

After adding Cognito protection to GET, the POST route was tested again without authentication.

Expected result:

`201 Created`

This confirmed that:

- GET remained protected
- POST remained intentionally public

---

# Controlled Failure Testing

The application was also tested with controlled failure scenarios.

Unexpected internal failures returned:

`500 Internal Server Error`

The client received a generic error response.

Technical error information was written to CloudWatch Logs instead of being exposed to the caller.

This confirms separation between client-facing error messages and internal troubleshooting information.

---

# Terraform Testing

Terraform configuration was tested using:

```text
terraform fmt
terraform validate
terraform plan
```

`terraform validate` completed successfully.

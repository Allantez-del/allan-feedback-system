# Monitoring and Observability

## Overview

The Allan Feedback System uses Amazon CloudWatch to monitor the API, Lambda function and DynamoDB table.

Monitoring was implemented to provide visibility into application health, failures, latency and database activity.

---

# CloudWatch Dashboard

The Terraform configuration creates the dashboard:

`allan-feedback-dashboard`

The dashboard contains metrics for the main serverless components.

## Lambda Metrics

The dashboard monitors:

- Invocations
- Errors
- Throttles
- Average Duration

These metrics help identify failed requests, execution problems, throttling and increased processing time.

---

## API Gateway Metrics

The dashboard monitors:

- Request Count
- 4xx responses
- 5xx responses

4xx responses can indicate invalid requests, authentication failures or other client-side problems.

5xx responses can indicate server-side failures.

---

## DynamoDB Metrics

The dashboard monitors:

- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- ReadThrottleEvents
- WriteThrottleEvents

The DynamoDB table uses on-demand billing, but these metrics are still useful for understanding workload and identifying throttling.

---

# Lambda Error Alarm

A CloudWatch alarm is configured:

`allan-feedback-lambda-errors`

The alarm monitors the AWS Lambda `Errors` metric.

Configuration:

- metric: `Errors`
- namespace: `AWS/Lambda`
- statistic: `Sum`
- period: 300 seconds
- evaluation periods: 1
- threshold: greater than 0
- missing data: not breaching

This means the alarm enters the alarm state if Lambda reports one or more execution errors during the evaluation period.

---

# Logging

The Lambda function writes logs to:

`/aws/lambda/allan-feedback-handler`

The log retention period is:

`14 days`

Application logging is used for technical troubleshooting while avoiding unnecessary long-term log storage.

Unexpected internal failures return generic messages to API clients while technical details remain in CloudWatch Logs.

---

# Important Monitoring Limitation

The current project contains one configured alarm for Lambda execution errors.

API Gateway 4xx and 5xx metrics and DynamoDB throttling metrics are visible on the dashboard, but separate alarms are not currently configured for them.

This distinction is important because a handled application error that returns an HTTP 500 response may not necessarily increment the Lambda `Errors` metric.

For that reason, API Gateway 5xx monitoring is also important.

---

# Production Improvements

A production environment could add alarms for:

- API Gateway 5xx responses
- unusually high API Gateway 4xx responses
- Lambda throttling
- Lambda duration
- DynamoDB throttling
- unusual request volume

Other improvements could include:

- structured JSON logging
- CloudWatch Logs Insights queries
- distributed tracing
- alarm notifications through Amazon SNS
- separate dashboards for dev, staging and production

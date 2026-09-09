# Cost Analysis

## Overview

The Allan Feedback System uses a serverless AWS architecture designed for low operational overhead and usage-based cost.

The main services are:

- Amazon API Gateway HTTP API
- AWS Lambda
- Amazon DynamoDB
- Amazon Cognito
- Amazon CloudWatch

The system does not require continuously running EC2 instances or a continuously provisioned relational database server.

This makes the architecture suitable for a customer feedback application with low, irregular or unpredictable traffic.

---

# 1. Main Cost Drivers

## API Gateway

Amazon API Gateway processes incoming HTTP requests.

Cost depends mainly on the number of API requests.

The application currently exposes:

- `POST /feedback`
- `GET /feedback`

A low-volume application therefore produces very little API activity.

As usage increases, API request volume becomes one of the primary cost drivers.

---

## AWS Lambda

The Lambda function handles both feedback submission and retrieval.

Lambda cost is influenced by:

- number of invocations
- execution duration
- configured memory
- total compute usage

Because Lambda runs only when invoked, the project does not pay for an application server sitting idle between requests.

This is an important advantage over a permanently running EC2-based application for this workload.

---

## Amazon DynamoDB

The feedback table uses:

`PAY_PER_REQUEST`

This means read and write capacity is not manually provisioned in advance.

The application pays according to actual database activity.

The main DynamoDB operations currently used are:

- `PutItem` for feedback submission
- `Scan` for feedback retrieval

For a small workload, on-demand billing avoids paying for unused provisioned capacity.

As the table grows, the current Scan-based GET operation can consume more read capacity than a targeted Query operation.

For this reason, improving the retrieval access pattern would provide both performance and cost benefits at larger scale.

---

## Amazon Cognito

Amazon Cognito is used to authenticate staff accessing the protected GET endpoint.

Customers submitting feedback through POST do not require Cognito accounts.

This keeps authentication focused on administrative access rather than creating accounts for every customer.

Cognito cost therefore depends primarily on the number of authenticated staff users and authentication activity.

---

## Amazon CloudWatch

CloudWatch is used for:

- Lambda logs
- application monitoring
- metrics
- dashboard visualization
- Lambda error alarm

CloudWatch cost can increase because of:

- high log ingestion volume
- long log retention periods
- additional custom metrics
- large numbers of alarms and dashboards

The Lambda log group currently has a retention period of:

`14 days`

This prevents application logs from being retained indefinitely and helps control unnecessary storage.

---

# 2. Low-Traffic Scenario

Consider a small application receiving approximately:

`100 feedback submissions per day`

This represents approximately:

`3,000 submissions per month`

The architecture remains well suited to this workload because:

- no EC2 server runs continuously
- Lambda runs only for requests
- DynamoDB uses on-demand billing
- API Gateway charges are request-driven
- only staff retrieval requires Cognito authentication

At this scale, most infrastructure remains idle for large portions of the day without requiring permanently provisioned compute capacity.

This is one of the main reasons serverless architecture is suitable for the project.

---

# 3. Higher-Traffic Scenario

Consider growth to:

`100,000 feedback submissions per day`

This represents approximately:

`3,000,000 submissions per month`

At this level, the architecture can still scale without introducing traditional application servers.

However, costs would increase with actual usage.

The most important cost areas would become:

- API Gateway request volume
- Lambda invocation and execution duration
- DynamoDB write requests
- DynamoDB read activity
- CloudWatch log ingestion
- storage growth

The architecture therefore scales financially with usage rather than requiring large infrastructure to be purchased in advance.

---

# 4. Impact of the GET Access Pattern

The current GET implementation uses DynamoDB:

`Scan`

and limits the returned result set to 20 records.

For the small demonstration dataset, this is acceptable.

However, Scan can become increasingly expensive as the table grows because DynamoDB must examine table data instead of directly targeting the required records.

A production version should use:

- `Query`
- pagination
- an appropriate secondary index
- a data model designed around staff retrieval requirements

This would reduce unnecessary reads and improve both performance and cost efficiency.

---

# 5. Serverless Compared with EC2

A traditional implementation could use:

- EC2 application server
- load balancer
- relational database
- operating-system administration
- server monitoring
- patching and maintenance

Those components may continue generating cost even during periods of little or no application traffic.

The current serverless architecture instead uses managed services that are primarily usage-driven.

For this project, serverless therefore avoids paying for significant permanently idle compute resources.

---

# 6. DynamoDB Compared with RDS

Amazon RDS could provide relational database functionality, but the current feedback system does not require:

- complex joins
- relational reporting
- multi-table transactions
- a complex relational schema

Each feedback submission can be represented as an independent DynamoDB item.

DynamoDB therefore provides a simpler serverless storage model for the current requirements.

For a future application requiring complex relational reporting or transactional relationships between many entities, RDS or Aurora could become more appropriate.

---

# 7. Cost Optimization Measures Already Implemented

The project already includes several cost-conscious design decisions:

- serverless compute with AWS Lambda
- API Gateway HTTP API
- DynamoDB on-demand billing
- 14-day CloudWatch log retention
- no permanently running EC2 instances
- no permanently provisioned database server
- one Lambda function handling the current API workload
- managed Cognito authentication
- limited GET result size

These choices keep the architecture simple while avoiding unnecessary infrastructure.

---

# 8. Future Cost Improvements

If application usage grows significantly, cost optimization should include:

- replacing DynamoDB Scan with Query
- adding pagination
- reviewing Lambda memory and execution duration
- reducing unnecessary logging
- monitoring API request patterns
- reviewing CloudWatch retention
- evaluating DynamoDB capacity strategy when traffic becomes predictable
- implementing AWS Budgets and cost alerts
- tagging resources consistently by project and environment

Terraform already applies project and environment tags to major resources, which helps organize cloud resources and supports future cost tracking.

---

# 9. Cost and Scalability Relationship

Serverless does not mean that the application has no cost.

Instead, the main advantage is that cost generally follows actual consumption.

At low traffic, the system can remain inexpensive because very little compute or database activity occurs.

At higher traffic, AWS automatically handles much of the infrastructure scaling, while the organization pays for the additional requests, compute and storage consumed.

This provides a good match for a feedback application where future request volume may be difficult to predict.

---

# 10. Conclusion

The serverless architecture provides an appropriate cost model for the Allan Feedback System.

For the current low-volume project, continuously running EC2 instances and database servers would introduce unnecessary infrastructure and operational overhead.

API Gateway, Lambda, DynamoDB and Cognito provide a usage-based architecture that can grow with the application.

The main future cost optimization priority is improving the DynamoDB GET access pattern as the dataset becomes larger.

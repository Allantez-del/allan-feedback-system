# Business Requirements

## Purpose

The Allan Feedback System must provide a simple, secure, and cost-conscious way to collect customer feedback and make it available to authorized staff.

## Functional Requirements

- The system must allow customers to submit feedback.
- The system must accept feedback over an HTTP API.
- The system must store submitted feedback persistently.
- The system must allow authorized staff to retrieve stored feedback.
- The system must support multiple users submitting feedback and authorized staff retrieving feedback.

## Operational Requirements

- The system must scale to changing request volumes without manually adding servers.
- The system must avoid traditional application-server management.
- The system must protect backend and database access from direct unauthorized client access.
- The system must provide logging and monitoring for operational visibility and troubleshooting.
- The system must follow the principle of least privilege for access to AWS resources.
- The system must remain simple to operate and cost-conscious for the project scale.

# Assumptions and Constraints

The following assumptions and constraints define the current Allan Feedback System demonstration:

- The default AWS deployment region is `eu-central-1`.
- The project operates at demonstration scale rather than as a high-volume production platform.
- Customers do not need user accounts to submit feedback; `POST /feedback` is public.
- Staff authentication is handled by Amazon Cognito, with a JWT protecting `GET /feedback`.
- No frontend is required for the current API demonstration.
- S3 frontend hosting is optional and is not implemented in this project.
- No EC2 instances, Amazon RDS database, or customer-managed VPC are required by the current solution.
- The GET operation currently uses a DynamoDB `Scan` with a 20-item limit and returns the newest records first. Pagination is not currently implemented.
- Terraform state is stored locally for development.
- The current development API allows permissive CORS for testing; production CORS should be stricter.
- Production hardening is future work and includes AWS WAF, stricter CORS, remote Terraform state, and CI/CD.
- The current implementation does not claim to provide services or infrastructure that are not listed in the implemented architecture.

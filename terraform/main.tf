resource "aws_dynamodb_table" "feedback" {
  name         = "allan-feedback"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "feedbackId"

  attribute {
    name = "feedbackId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project     = "Allan Feedback System"
    Environment = "dev"
  }
}

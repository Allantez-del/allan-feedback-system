import json
import os
import uuid
from datetime import datetime, timezone

import boto3


table = boto3.resource("dynamodb").Table(
    os.environ["FEEDBACK_TABLE_NAME"]
)

ALLOWED_CATEGORIES = {
    "service",
    "product",
    "delivery",
    "website",
    "complaint",
    "suggestion",
    "other",
}


def handler(event, context):
    try:
        body = event.get("body") or "{}"
        payload = json.loads(body) if isinstance(body, str) else body

        # Validate required fields
        rating = payload.get("rating")
        category = payload.get("category")
        message = payload.get("message")

        if not isinstance(rating, int) or not 1 <= rating <= 5:
            return response(
                400,
                {"error": "rating must be an integer from 1 to 5"},
            )

        if category not in ALLOWED_CATEGORIES:
            return response(
                400,
                {"error": "Invalid category"},
            )

        if not isinstance(message, str) or not message.strip():
            return response(
                400,
                {"error": "message is required"},
            )

        item = {
            "feedbackId": str(uuid.uuid4()),
            "rating": rating,
            "category": category,
            "message": message.strip(),
            "submittedAt": datetime.now(timezone.utc).isoformat(),
        }

        # Optional fields
        if payload.get("customerName"):
            item["customerName"] = payload["customerName"].strip()

        if payload.get("email"):
            item["email"] = payload["email"].strip()

        table.put_item(Item=item)

        return response(
            201,
            {
                "message": "Feedback submitted successfully.",
                "feedbackId": item["feedbackId"],
            },
        )

    except (json.JSONDecodeError, TypeError, AttributeError):
        return response(
            400,
            {"error": "Invalid JSON body"},
        )

    except Exception:
        return response(
            500,
            {"error": "Internal server error"},
        )


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body),
    }
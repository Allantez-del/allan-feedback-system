import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

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

MAX_FEEDBACK_RESULTS = 20


def handler(event, context):
    try:
        method = (
            event.get("requestContext", {})
            .get("http", {})
            .get("method")
        )

        # Direct Lambda tests can provide the method explicitly
        if not method:
            method = event.get("httpMethod")

        if method == "GET":
            return get_feedback()

        if method == "POST":
            return submit_feedback(event)

        return response(
            405,
            {"error": "Method not allowed"},
        )

    except Exception as error:
        print(f"Unhandled error: {type(error).__name__}")

        return response(
            500,
            {"error": "Internal server error"},
        )


def submit_feedback(event):
    try:
        body = event.get("body") or "{}"
        payload = json.loads(body) if isinstance(body, str) else body

        if not isinstance(payload, dict):
            return response(
                400,
                {"error": "JSON body must be an object"},
            )

        rating = payload.get("rating")
        category = payload.get("category")
        message = payload.get("message")
        customer_name = payload.get("customerName")
        email = payload.get("email")

        if not isinstance(rating, int) or isinstance(rating, bool):
            return response(
                400,
                {"error": "rating must be an integer from 1 to 5"},
            )

        if not 1 <= rating <= 5:
            return response(
                400,
                {"error": "rating must be an integer from 1 to 5"},
            )

        if not isinstance(category, str) or category not in ALLOWED_CATEGORIES:
            return response(
                400,
                {"error": "Invalid category"},
            )

        if not isinstance(message, str) or not message.strip():
            return response(
                400,
                {"error": "message is required"},
            )

        if len(message.strip()) > 2000:
            return response(
                400,
                {"error": "message must not exceed 2000 characters"},
            )

        if customer_name is not None and not isinstance(customer_name, str):
            return response(
                400,
                {"error": "customerName must be a string"},
            )

        if email is not None and not isinstance(email, str):
            return response(
                400,
                {"error": "email must be a string"},
            )

        item = {
            "feedbackId": str(uuid.uuid4()),
            "rating": rating,
            "category": category,
            "message": message.strip(),
            "submittedAt": datetime.now(timezone.utc).isoformat(),
        }

        if customer_name and customer_name.strip():
            item["customerName"] = customer_name.strip()

        if email and email.strip():
            item["email"] = email.strip()

        table.put_item(Item=item)

        return response(
            201,
            {
                "message": "Feedback submitted successfully.",
                "feedbackId": item["feedbackId"],
            },
        )

    except json.JSONDecodeError:
        return response(
            400,
            {"error": "Invalid JSON body"},
        )

    except Exception as error:
        print(
            f"Database or processing error: {type(error).__name__}"
        )

        return response(
            500,
            {"error": "Internal server error"},
        )


def get_feedback():
    result = table.scan(
        Limit=MAX_FEEDBACK_RESULTS
    )

    items = result.get("Items", [])

    # Newest submissions first
    items.sort(
        key=lambda item: item.get("submittedAt", ""),
        reverse=True,
    )

    return response(
        200,
        {
            "items": items,
            "count": len(items),
        },
    )


def decimal_serializer(value):
    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)

        return float(value)

    raise TypeError


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(
            body,
            default=decimal_serializer,
        ),
    }
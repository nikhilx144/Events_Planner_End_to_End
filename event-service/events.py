import os
import json
import uuid
import boto3
import jwt
from datetime import datetime
from boto3.dynamodb.conditions import Key

JWT_SECRET = os.environ.get("JWT_SECRET", "mysecretkey")
EVENTS_TABLE = os.environ.get("EVENTS_TABLE", "EventsTable")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(EVENTS_TABLE)

def response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }

def get_email_from_event(event):
    hdrs = event.get("headers") or {}
    auth = hdrs.get("Authorization") or hdrs.get("authorization")
    if not auth:
        return None, "Authorization header missing"
    if not auth.startswith("Bearer "):
        return None, "Authorization header must be 'Bearer <token>'"
    token = auth.split(" ", 1)[1]
    try:
        decoded = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return decoded.get("email"), None
    except Exception as e:
        return None, f"Invalid token: {str(e)}"

def create_event(user_email, payload):
    # required fields: title, date, details (time/venue optional)
    title = payload.get("title")
    date = payload.get("date")
    details = payload.get("details")
    if not (title and date and details):
        return None, "title, date and details are required"

    item = {
        "userId": user_email,
        "eventId": str(uuid.uuid4()),
        "title": title,
        "date": date,
        "time": payload.get("time", ""),
        "venue": payload.get("venue", ""),
        "details": details,
        "createdAt": datetime.utcnow().isoformat()
    }
    table.put_item(Item=item)
    return item, None

def list_events(user_email):
    # Query by userId
    resp = table.query(
        KeyConditionExpression=Key("userId").eq(user_email)
    )
    items = resp.get("Items", [])
    # sort by date/time optionally
    items_sorted = sorted(items, key=lambda x: (x.get("date",""), x.get("time","")))
    return items_sorted

def update_event(user_email, payload):
    event_id = payload.get("eventId")
    if not event_id:
        return None, "eventId is required"
    # Build UpdateExpression
    update_fields = {}
    allowed = ["title","date","time","venue","details"]
    for k in allowed:
        if k in payload:
            update_fields[k] = payload[k]
    if not update_fields:
        return None, "no updatable fields provided"

    expr = "SET " + ", ".join([f"#{k}=:{k}" for k in update_fields])
    attr_names = {f"#{k}": k for k in update_fields}
    attr_values = {f":{k}": v for k, v in update_fields.items()}

    resp = table.update_item(
        Key={"userId": user_email, "eventId": event_id},
        UpdateExpression=expr,
        ExpressionAttributeNames=attr_names,
        ExpressionAttributeValues=attr_values,
        ReturnValues="ALL_NEW",
        ConditionExpression=Key("userId").eq(user_email)
    )
    return resp.get("Attributes"), None

def delete_event(user_email, payload):
    event_id = payload.get("eventId")
    if not event_id:
        return None, "eventId is required"
    table.delete_item(Key={"userId": user_email, "eventId": event_id})
    return {"deleted": event_id}, None

def lambda_handler(event, context):
    method = event.get("httpMethod")
    email, err = get_email_from_event(event)
    if err:
        return response(401, {"error": err})

    # parse body for POST/PUT/DELETE; GET expects no body
    body = {}
    if method in ("POST", "PUT", "DELETE"):
        try:
            body = json.loads(event.get("body") or "{}")
        except:
            return response(400, {"error": "Invalid JSON body"})

    try:
        if method == "POST":
            item, err = create_event(email, body)
            if err:
                return response(400, {"error": err})
            return response(201, {"message": "created", "item": item})

        elif method == "GET":
            items = list_events(email)
            return response(200, {"items": items})

        elif method == "PUT":
            updated, err = update_event(email, body)
            if err:
                return response(400, {"error": err})
            return response(200, {"message": "updated", "item": updated})

        elif method == "DELETE":
            deleted, err = delete_event(email, body)
            if err:
                return response(400, {"error": err})
            return response(200, {"message": "deleted", "result": deleted})

        else:
            return response(405, {"error": f"Method {method} not allowed"})
    except Exception as e:
        # for debugging - return minimal message
        return response(500, {"error": "internal server error", "detail": str(e)})
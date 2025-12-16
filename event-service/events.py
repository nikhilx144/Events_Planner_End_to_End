import json
import boto3
import uuid
import jwt
import os
from datetime import datetime
from decimal import Decimal

# Environment variables
SECRET = os.environ.get("JWT_SECRET", "mysecretkey")
EVENTS_TABLE = os.environ.get("EVENTS_TABLE", "EventsTable")

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(EVENTS_TABLE)

def cors_headers():
    """Return CORS headers for all responses"""
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
        "Content-Type": "application/json"
    }

def response(status_code, body):
    """Helper to format API Gateway response"""
    return {
        "statusCode": status_code,
        "headers": cors_headers(),
        "body": json.dumps(body)
    }

def verify_jwt(token):
    """Verify and decode JWT token"""
    try:
        # Remove 'Bearer ' prefix if present
        if token.startswith('Bearer '):
            token = token[7:]
        
        payload = jwt.decode(token, SECRET, algorithms=['HS256'])
        return payload.get('email')
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def get_user_email_from_event(event):
    """Extract and verify JWT token from request"""
    headers = event.get('headers', {})
    
    # Try different header capitalizations (API Gateway can change case)
    auth_header = (headers.get('Authorization') or 
                   headers.get('authorization') or 
                   headers.get('AUTHORIZATION'))
    
    if not auth_header:
        return None
    
    return verify_jwt(auth_header)

def lambda_handler(event, context):
    """Main Lambda handler for Events CRUD operations"""
    
    print(f"Received event: {json.dumps(event)}")
    
    # Handle OPTIONS for CORS
    if event.get('httpMethod') == 'OPTIONS':
        return response(200, {"message": "OK"})
    
    # Verify authentication
    user_email = get_user_email_from_event(event)
    if not user_email:
        return response(401, {"error": "Unauthorized - Invalid or missing token"})
    
    http_method = event.get('httpMethod')
    
    try:
        if http_method == 'GET':
            return handle_get_events(user_email)
        
        elif http_method == 'POST':
            return handle_create_event(user_email, event)
        
        elif http_method == 'PUT':
            return handle_update_event(user_email, event)
        
        elif http_method == 'DELETE':
            return handle_delete_event(user_email, event)
        
        else:
            return response(405, {"error": f"Method {http_method} not allowed"})
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {"error": f"Internal server error: {str(e)}"})

def handle_get_events(user_email):
    """GET /events - Fetch all events for user"""
    try:
        # Query DynamoDB for all events belonging to this user
        result = table.query(
            KeyConditionExpression='userId = :uid',
            ExpressionAttributeValues={
                ':uid': user_email
            }
        )
        
        items = result.get('Items', [])
        
        # Convert Decimal to float for JSON serialization
        items = json.loads(json.dumps(items, default=decimal_default))
        
        print(f"Found {len(items)} events for user {user_email}")
        
        return response(200, {
            "items": items,
            "count": len(items)
        })
    
    except Exception as e:
        print(f"Error fetching events: {str(e)}")
        return response(500, {"error": f"Failed to fetch events: {str(e)}"})

def handle_create_event(user_email, event):
    """POST /events - Create new event"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        title = body.get('title', '').strip()
        date = body.get('date', '').strip()
        details = body.get('details', '').strip()
        
        if not title or not date or not details:
            return response(400, {"error": "Missing required fields: title, date, details"})
        
        # Optional fields
        time = body.get('time', '').strip()
        venue = body.get('venue', '').strip()
        
        # Generate unique event ID
        event_id = str(uuid.uuid4())
        
        # Create timestamp for sorting
        timestamp = int(datetime.now().timestamp())
        
        # Create event item
        item = {
            'userId': user_email,           # Partition key
            'eventId': event_id,             # Sort key
            'title': title,
            'date': date,
            'time': time if time else 'Not specified',
            'venue': venue if venue else 'Not specified',
            'details': details,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Save to DynamoDB
        table.put_item(Item=item)
        
        print(f"Created event {event_id} for user {user_email}")
        
        return response(201, {
            "message": "Event created successfully",
            "event": item
        })
    
    except Exception as e:
        print(f"Error creating event: {str(e)}")
        return response(500, {"error": f"Failed to create event: {str(e)}"})

def handle_update_event(user_email, event):
    """PUT /events - Update existing event"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        event_id = body.get('eventId')
        if not event_id:
            return response(400, {"error": "Missing eventId"})
        
        # Build update expression
        update_expr = "SET updatedAt = :updated"
        expr_values = {':updated': int(datetime.now().timestamp())}
        expr_names = {}
        
        # Update fields if provided
        if 'title' in body:
            update_expr += ", title = :title"
            expr_values[':title'] = body['title']
        
        if 'date' in body:
            update_expr += ", #dt = :date"  # 'date' is reserved word
            expr_values[':date'] = body['date']
            expr_names['#dt'] = 'date'
        
        if 'time' in body:
            update_expr += ", #tm = :time"  # 'time' is reserved word
            expr_values[':time'] = body['time']
            expr_names['#tm'] = 'time'
        
        if 'venue' in body:
            update_expr += ", venue = :venue"
            expr_values[':venue'] = body['venue']
        
        if 'details' in body:
            update_expr += ", details = :details"
            expr_values[':details'] = body['details']
        
        # Update the item
        result = table.update_item(
            Key={
                'userId': user_email,
                'eventId': event_id
            },
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_values,
            ExpressionAttributeNames=expr_names if expr_names else None,
            ReturnValues='ALL_NEW'
        )
        
        updated_item = result.get('Attributes', {})
        updated_item = json.loads(json.dumps(updated_item, default=decimal_default))
        
        return response(200, {
            "message": "Event updated successfully",
            "event": updated_item
        })
    
    except Exception as e:
        print(f"Error updating event: {str(e)}")
        return response(500, {"error": f"Failed to update event: {str(e)}"})

def handle_delete_event(user_email, event):
    """DELETE /events - Delete event"""
    try:
        # Event ID from body (preferred) or query string
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except:
                body = {}
        
        query_params = event.get('queryStringParameters', {}) or {}
        
        event_id = body.get('eventId') or query_params.get('eventId')
        
        if not event_id:
            return response(400, {"error": "eventId is required"})
        
        # Delete from DynamoDB
        table.delete_item(
            Key={
                'userId': user_email,
                'eventId': event_id
            }
        )
        
        print(f"Deleted event {event_id} for user {user_email}")
        
        return response(200, {
            "message": "Event deleted successfully",
            "eventId": event_id
        })
    
    except Exception as e:
        print(f"Error deleting event: {str(e)}")
        return response(500, {"error": f"Failed to delete event: {str(e)}"})

def decimal_default(obj):
    """Helper to convert Decimal to float for JSON"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError
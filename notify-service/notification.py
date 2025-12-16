import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Environment variables
EVENTS_TABLE = os.environ.get("EVENTS_TABLE", "EventsTable")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
USERS_TABLE = os.environ.get("USERS_TABLE", "UsersTable")

# AWS clients
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
events_table = dynamodb.Table(EVENTS_TABLE)
users_table = dynamodb.Table(USERS_TABLE)

def lambda_handler(event, context):
    """
    EventBridge triggers this Lambda daily at 8 AM UTC.
    Checks for events happening tomorrow and sends email reminders.
    """
    
    print("Starting notification check...")
    
    # Calculate tomorrow's date
    tomorrow = datetime.now() + timedelta(days=1)
    tomorrow_str = tomorrow.strftime("%Y-%m-%d")
    
    print(f"Checking for events on: {tomorrow_str}")
    
    try:
        # Scan DynamoDB for all events (since we need to check all users)
        # In production, you might want to use a GSI for better performance
        response = events_table.scan()
        all_events = response.get('Items', [])
        
        # Continue scanning if there are more items
        while 'LastEvaluatedKey' in response:
            response = events_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            all_events.extend(response.get('Items', []))
        print(f"Total events in database: {len(all_events)}")
        # Filter events for tomorrow
        tomorrow_events = [
            event for event in all_events 
            if event.get('date') == tomorrow_str
        ]
        
        print(f"Events happening tomorrow: {len(tomorrow_events)}")
        
        # Group events by userId
        events_by_user = {}
        for event in tomorrow_events:
            user_id = event.get('userId')
            if user_id:
                if user_id not in events_by_user:
                    events_by_user[user_id] = []
                events_by_user[user_id].append(event)
        
        # Send notifications for each user
        notifications_sent = 0
        errors = 0
        
        for user_id, user_events in events_by_user.items():
            try:
                send_notification(user_id, user_events, tomorrow_str)
                notifications_sent += 1
                print(f"✓ Sent notification to {user_id}")
            except Exception as e:
                errors += 1
                print(f"✗ Failed to send notification to {user_id}: {str(e)}")
        
        result = {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Notification check complete",
                "total_events": len(all_events),
                "tomorrow_events": len(tomorrow_events),
                "notifications_sent": notifications_sent,
                "errors": errors,
                "date_checked": tomorrow_str
            })
        }
        
        print(f"Summary: {notifications_sent} notifications sent, {errors} errors")
        return result
        
    except Exception as e:
        print(f"Error in notification handler: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e)
            })
        }

def send_notification(user_id, events, event_date):
    """
    Send email notification to user about their upcoming events.
    
    Args:
        user_id: Email of the user
        events: List of events happening tomorrow
        event_date: Date string (YYYY-MM-DD)
    """
    
    # Get user details to get their full name
    try:
        user_response = users_table.get_item(Key={"email": user_id})
        user = user_response.get('Item', {})
        full_name = user.get('full_name', 'User')
    except Exception as e:
        print(f"Warning: Could not fetch user details for {user_id}: {str(e)}")
        full_name = 'User'
    
    # Build email content
    subject = f"📅 Reminder: You have {len(events)} event(s) tomorrow ({event_date})"
    
    # Email body
    body_lines = [
        f"Hi {full_name},",
        "",
        f"This is a friendly reminder about your upcoming event(s) on {event_date}:",
        "",
        "=" * 60,
        ""
    ]
    
    for i, event in enumerate(events, 1):
        body_lines.append(f"Event {i}: {event.get('title', 'Untitled')}")
        body_lines.append(f"  📅 Date: {event.get('date', 'N/A')}")
        body_lines.append(f"  🕐 Time: {event.get('time', 'Not specified')}")
        body_lines.append(f"  📍 Venue: {event.get('venue', 'Not specified')}")
        body_lines.append(f"  📝 Details: {event.get('details', 'No details')}")
        body_lines.append("")
        body_lines.append("-" * 60)
        body_lines.append("")
    
    body_lines.extend([
        "",
        "Don't forget to prepare for your event(s)!",
        "",
        "Best regards,",
        "Event Planner Team",
        "",
        "---",
        "This is an automated reminder from Event Planner.",
        "You're receiving this because you have events scheduled for tomorrow."
    ])
    
    email_body = "\n".join(body_lines)
    
    # Send via SNS
    try:
        response = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=email_body,
            MessageAttributes={
                'user_email': {
                    'DataType': 'String',
                    'StringValue': user_id
                },
                'event_date': {
                    'DataType': 'String',
                    'StringValue': event_date
                },
                'event_count': {
                    'DataType': 'Number',
                    'StringValue': str(len(events))
                }
            }
        )
        
        message_id = response.get('MessageId')
        print(f"Email sent successfully. MessageId: {message_id}")
        
        return {
            "success": True,
            "message_id": message_id
        }
        
    except Exception as e:
        print(f"Failed to send email via SNS: {str(e)}")
        raise

def decimal_default(obj):
    """Helper to convert Decimal to float for JSON"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError
import json
from utils import hash_password, get_users_table
import uuid

def lambda_handler(event, context):
    # Parse request body
    body = json.loads(event.get("body", "{}"))
    
    full_name = body.get("full_name")
    email = body.get("email")
    password = body.get("password")
    confirm = body.get("confirm_password")
    
    # Validate all required fields
    if not (full_name and email and password and confirm):
        return {
            "statusCode": 400,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Missing required fields"})
        }
    
    # Check if passwords match
    if password != confirm:
        return {
            "statusCode": 400,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Passwords do not match"})
        }
    
    table = get_users_table()
    
    # Check if user already exists
    try:
        response = table.get_item(Key={"email": email})
        if "Item" in response:
            return {
                "statusCode": 409,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Content-Type": "application/json"
                },
                "body": json.dumps({"error": "User already exists"})
            }
    except Exception as e:
        print(f"Error checking user: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Database error"})
        }
    
    # Hash password
    hashed = hash_password(password)
    
    # Create new user
    try:
        table.put_item(Item={
            "email": email,
            "userId": str(uuid.uuid4()),
            "full_name": full_name,
            "password": hashed
        })
    except Exception as e:
        print(f"Error creating user: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Failed to create user"})
        }
    
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Content-Type": "application/json"
        },
        "body": json.dumps({"message": "Signup successful", "email": email})
    }
import json
from utils import verify_password, generate_jwt, get_users_table

def lambda_handler(event, context):
    # Parse request body
    body = json.loads(event.get("body", "{}"))
    
    email = body.get("email")
    password = body.get("password")
    
    # Validate credentials provided
    if not (email and password):
        return {
            "statusCode": 400,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Missing credentials"})
        }
    
    table = get_users_table()
    
    # Get user from database
    try:
        response = table.get_item(Key={"email": email})
    except Exception as e:
        print(f"Database error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Database error"})
        }
    
    # Check if user exists
    if "Item" not in response:
        return {
            "statusCode": 404,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "User not found"})
        }
    
    user = response["Item"]
    
    # Verify password
    if not verify_password(password, user["password"]):
        return {
            "statusCode": 401,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Invalid password"})
        }
    
    # Generate JWT token
    token = generate_jwt(email)
    
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Login successful",
            "token": token,
            "email": email,
            "full_name": user.get("full_name", "")
        })
    }
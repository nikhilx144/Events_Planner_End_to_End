import json
from utils import hash_password, get_users_table
import uuid

def lambda_handler(event, context):

    body = json.loads(event.get("body", "{}"))

    full_name = body.get("full_name")
    email = body.get("email")
    password = body.get("password")
    confirm = body.get("confirm_password")

    if not (full_name and email and password and confirm):
        return {"statusCode": 400, "body": json.dumps({"error": "Missing fields"})}

    if password != confirm:
        return {"statusCode": 400, "body": json.dumps({"error": "Passwords do not match"})}

    table = get_users_table()

    # Check if user exists
    response = table.get_item(Key={"email": email})
    if "Item" in response:
        return {"statusCode": 409, "body": json.dumps({"error": "User already exists"})}

    hashed = hash_password(password)

    table.put_item(Item={
        "email": email,
        "userId": str(uuid.uuid4()),
        "full_name": full_name,
        "password": hashed
    })

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Signup successful"})
    }

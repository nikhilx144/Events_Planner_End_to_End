import json
from utils import verify_password, generate_jwt, get_users_table

def lambda_handler(event, context):

    body = json.loads(event.get("body", "{}"))

    email = body.get("email")
    password = body.get("password")

    if not (email and password):
        return {"statusCode": 400, "body": json.dumps({"error": "Missing credentials"})}

    table = get_users_table()
    response = table.get_item(Key={"email": email})

    if "Item" not in response:
        return {"statusCode": 404, "body": json.dumps({"error": "User not found"})}

    user = response["Item"]

    if not verify_password(password, user["password"]):
        return {"statusCode": 401, "body": json.dumps({"error": "Invalid password"})}

    token = generate_jwt(email)

    return {
        "statusCode": 200,
        "body": json.dumps({"token": token})
    }

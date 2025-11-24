import boto3
import bcrypt
import jwt
import os
from datetime import datetime, timedelta

SECRET = os.environ.get("JWT_SECRET", "mysecretkey")  # You will replace this in Lambda env variables

def hash_password(password: str) -> str:
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
    return hashed.decode("utf-8")

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))

def generate_jwt(email: str) -> str:
    payload = {
        "email": email,
        "exp": datetime.utcnow() + timedelta(hours=1)
    }
    token = jwt.encode(payload, SECRET, algorithm="HS256")
    return token

def get_users_table():
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table("UsersTable")

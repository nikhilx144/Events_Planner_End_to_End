import boto3
import hashlib
import hmac
import jwt
import os
from datetime import datetime, timedelta

SECRET = os.environ.get("JWT_SECRET", "mysecretkey")

def hash_password(password: str) -> str:
    """Hash password using SHA256"""
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def verify_password(password: str, hashed: str) -> bool:
    """Verify SHA256 hashed password"""
    return hash_password(password) == hashed

def generate_jwt(email: str) -> str:
    payload = {
        "email": email,
        "exp": datetime.utcnow() + timedelta(hours=1)
    }
    return jwt.encode(payload, SECRET, algorithm="HS256")

def get_users_table():
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table("UsersTable")

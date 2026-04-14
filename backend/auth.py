import re
from werkzeug.security import check_password_hash, generate_password_hash


def is_valid_email(email: str) -> bool:
    pattern = r"^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$"
    return bool(re.match(pattern, email))


def is_valid_password(password: str) -> bool:
    pattern = r"^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{6,}$"
    return bool(re.match(pattern, password))


def hash_password(password: str) -> str:
    return generate_password_hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return check_password_hash(password_hash, password)
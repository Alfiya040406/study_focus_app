from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

from auth import hash_password, is_valid_password, verify_password
from database import Base, engine, get_db
from models import User
from schemas import LoginRequest, LoginResponse, MessageResponse, SignupRequest

app = FastAPI()

Base.metadata.create_all(bind=engine)


@app.get("/")
def root():
    return {"message": "Backend is running"}


@app.post("/signup", response_model=MessageResponse)
def signup(data: SignupRequest, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == data.email).first()

    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    if not is_valid_password(data.password):
        raise HTTPException(
            status_code=400,
            detail="Password must contain at least one uppercase letter, one number, one special character, and be at least 6 characters long",
        )

    new_user = User(
        username=data.username,
        email=data.email,
        hashed_password=hash_password(data.password),
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "Signup successful"}


@app.post("/login", response_model=LoginResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {
        "success": True,
        "message": "Login successful",
        "username": user.username,
    }
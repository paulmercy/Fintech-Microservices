from fastapi import FastAPI, HTTPException, Depends, Header
import uvicorn
from pydantic import BaseModel, validator
import os
import logging
from sqlalchemy import create_engine, Column, Integer, String, Float, MetaData, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import requests

app = FastAPI(title="User Account Service")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database connection
DB_HOST = os.getenv("DB_HOST", "yugabytedb")
DB_PORT = os.getenv("DB_PORT", "5433")
DB_NAME = os.getenv("DB_NAME", "fintech")
DB_USER = os.getenv("DB_USER", "yugabyte")
DB_PASSWORD = os.getenv("DB_PASSWORD", "yugabyte")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Data models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    balance = Column(Float, default=0.0)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class UserCreate(BaseModel):
    username: str
    email: str
    initial_balance: float = 0.0

    @validator("username")
    def username_must_be_alphanumeric(cls, username):
        if not username.isalnum():
            raise ValueError("Username must be alphanumeric")
        return username

    @validator("email")
    def email_must_contain_at(cls, email):
        if "@" not in email:
            raise ValueError("Email must contain @")
        return email

    @validator("initial_balance")
    def initial_balance_must_be_positive(cls, initial_balance):
        if initial_balance < 0:
            raise ValueError("Initial balance must be positive")
        return initial_balance

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    balance: float

class BalanceUpdate(BaseModel):
    amount: float

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "User Account Service is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/users/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    try:
        db_user = User(username=user.username, email=user.email, balance=user.initial_balance)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        logger.info(f"Created user with ID: {db_user.id}")
        return db_user
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating user: {str(e)}")

@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.put("/users/{user_id}/balance", response_model=UserResponse)
def update_balance(user_id: int, balance_update: BalanceUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.balance + balance_update.amount < 0:
        raise HTTPException(status_code=400, detail="Insufficient balance")
    
    user.balance += balance_update.amount
    db.commit()
    db.refresh(user)
    logger.info(f"Updated balance for user {user_id}: new balance = {user.balance}")
    return user

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
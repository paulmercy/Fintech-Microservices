from fastapi import FastAPI, HTTPException, Depends
import uvicorn
from pydantic import BaseModel, validator
import os
import logging
import requests
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, MetaData, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

app = FastAPI(title="Transaction Service")

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

# User service URL
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8000")

# Data models
class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    amount = Column(Float)
    transaction_type = Column(String)  # deposit, withdrawal, transfer
    description = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class TransactionCreate(BaseModel):
    user_id: int
    amount: float
    transaction_type: str
    description: str = None

    @validator("transaction_type")
    def transaction_type_must_be_valid(cls, transaction_type):
        if transaction_type not in ["deposit", "withdrawal", "transfer"]:
            raise ValueError("Transaction type must be deposit, withdrawal, or transfer")
        return transaction_type

    @validator("amount")
    def amount_must_be_positive(cls, amount):
        if amount <= 0:
            raise ValueError("Amount must be positive")
        return amount

class TransactionResponse(BaseModel):
    id: int
    user_id: int
    amount: float
    transaction_type: str
    description: str = None
    timestamp: datetime

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "Transaction Service is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/transactions/", response_model=TransactionResponse)
def create_transaction(transaction: TransactionCreate, db: Session = Depends(get_db)):
    # Create transaction record
    db_transaction = Transaction(
        user_id=transaction.user_id,
        amount=transaction.amount,
        transaction_type=transaction.transaction_type,
        description=transaction.description
    )
    
    try:
        # Update user balance
        amount = transaction.amount
        if transaction.transaction_type == "withdrawal":
            amount = -amount
            
        response = requests.put(
            f"{USER_SERVICE_URL}/users/{transaction.user_id}/balance",
            json={"amount": amount}
        )
        
        if response.status_code == 404:
            raise HTTPException(status_code=404, detail="User not found")
        elif response.status_code == 400:
            raise HTTPException(status_code=400, detail="Insufficient balance")
        elif response.status_code != 200:
            raise HTTPException(status_code=500, detail="Failed to update user balance")
        
        # Save transaction
        db.add(db_transaction)
        db.commit()
        db.refresh(db_transaction)
        
        logger.info(f"Created transaction with ID: {db_transaction.id}")
        return db_transaction
    except requests.RequestException as e:
        logger.error(f"Error communicating with user service: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error communicating with user service: {str(e)}")
    except Exception as e:
        logger.error(f"Error creating transaction: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating transaction: {str(e)}")

@app.get("/transactions/user/{user_id}")
def get_user_transactions(user_id: int, db: Session = Depends(get_db)):
    transactions = db.query(Transaction).filter(Transaction.user_id == user_id).all()
    return transactions

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
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
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Counter, Histogram
from circuitbreaker import circuit
import time
from redis import Redis
from rq import Queue
import json

# Initialize OpenTelemetry
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)
otlp_exporter = OTLPSpanExporter(endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317"))
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Initialize Redis and RQ
redis_conn = Redis(host=os.getenv("REDIS_HOST", "redis"), port=6379)
transaction_queue = Queue('transactions', connection=redis_conn)

# Initialize Prometheus metrics
REQUEST_COUNT = Counter('transaction_service_requests_total', 'Total requests to transaction service', ['endpoint', 'method', 'status'])
REQUEST_LATENCY = Histogram('transaction_service_request_latency_seconds', 'Request latency in seconds', ['endpoint'])
TRANSACTION_COUNT = Counter('transactions_total', 'Total number of transactions', ['type', 'status'])

app = FastAPI(title="Transaction Service",
             description="Transaction management service for fintech application",
             version="1.0.0",
             docs_url="/docs",
             redoc_url="/redoc")

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

# Circuit breaker configuration
@circuit(failure_threshold=5, recovery_timeout=60)
def update_user_balance(user_id: int, amount: float):
    response = requests.put(
        f"{USER_SERVICE_URL}/users/{user_id}/balance",
        json={"amount": amount}
    )
    if response.status_code >= 500:
        raise HTTPException(status_code=response.status_code, detail="User service error")
    return response

# Background job for processing transactions
def process_transaction(transaction_data: dict):
    with tracer.start_as_current_span("process_transaction") as span:
        span.set_attribute("transaction.id", transaction_data["id"])
        span.set_attribute("transaction.type", transaction_data["transaction_type"])
        
        try:
            # Update user balance
            amount = transaction_data["amount"]
            if transaction_data["transaction_type"] == "withdrawal":
                amount = -amount
                
            response = update_user_balance(transaction_data["user_id"], amount)
            
            if response.status_code == 200:
                TRANSACTION_COUNT.labels(type=transaction_data["transaction_type"], status="success").inc()
            else:
                TRANSACTION_COUNT.labels(type=transaction_data["transaction_type"], status="failed").inc()
                
            return response.json()
        except Exception as e:
            TRANSACTION_COUNT.labels(type=transaction_data["transaction_type"], status="failed").inc()
            raise

@app.middleware("http")
async def add_metrics(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    REQUEST_COUNT.labels(endpoint=request.url.path, method=request.method, status=response.status_code).inc()
    REQUEST_LATENCY.labels(endpoint=request.url.path).observe(time.time() - start_time)
    return response

@app.post("/transactions/", response_model=TransactionResponse)
def create_transaction(transaction: TransactionCreate, db: Session = Depends(get_db)):
    with tracer.start_as_current_span("create_transaction") as span:
        span.set_attribute("transaction.type", transaction.transaction_type)
        span.set_attribute("transaction.amount", transaction.amount)
        
        # Create transaction record
        db_transaction = Transaction(
            user_id=transaction.user_id,
            amount=transaction.amount,
            transaction_type=transaction.transaction_type,
            description=transaction.description
        )
        
        try:
            # Save transaction first
            db.add(db_transaction)
            db.commit()
            db.refresh(db_transaction)
            
            # Queue the balance update
            transaction_data = {
                "id": db_transaction.id,
                "user_id": transaction.user_id,
                "amount": transaction.amount,
                "transaction_type": transaction.transaction_type
            }
            transaction_queue.enqueue(process_transaction, transaction_data)
            
            logger.info(f"Created transaction with ID: {db_transaction.id}")
            return db_transaction
        except Exception as e:
            logger.error(f"Error creating transaction: {str(e)}")
            db.rollback()
            raise HTTPException(status_code=400, detail=f"Error creating transaction: {str(e)}")

@app.get("/transactions/user/{user_id}")
def get_user_transactions(user_id: int, db: Session = Depends(get_db)):
    transactions = db.query(Transaction).filter(Transaction.user_id == user_id).all()
    return transactions

# Initialize OpenTelemetry instrumentation
FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(engine=engine)

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
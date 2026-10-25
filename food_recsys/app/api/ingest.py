from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Query, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.transaction import (
    TransactionBatchIn, 
    TransactionIn,
    IngestResponse, 
    SmsIngestRequest,
    FoodOrdersBatchIn,
)
from app.ingestion.pipeline import ingest_transactions
from app.ingestion.sms_parser import parse_sms_batch
from app.ingestion.statement_parser import parse_statement_csv
from app.profile.builder import build_taste_profile
from app.mock.transactions import generate_mock_transactions_for_persona, PERSONA_PROFILES

router = APIRouter(prefix="/ingest", tags=["Ingestion"])


@router.post("", response_model=IngestResponse)
async def ingest_batch(
    payload: TransactionBatchIn,
    rebuild_profiles: bool = Query(True, description="Automatically recompute taste profiles for affected users"),
    session: AsyncSession = Depends(get_db),
):
    """Ingest a batch of raw UPI transactions, classifying food purchases and updating profiles."""
    if not payload.transactions:
        raise HTTPException(status_code=400, detail="Transaction list cannot be empty")

    res = await ingest_transactions(session, payload.transactions)

    if rebuild_profiles:
        for user_id in res.affected_users:
            await build_taste_profile(session, user_id)

    return res


@router.post("/sms")
async def ingest_sms_messages(
    payload: SmsIngestRequest,
    rebuild_profile: bool = Query(True, description="Automatically recompute user taste profile"),
    session: AsyncSession = Depends(get_db),
):
    """Parse real-world bank/UPI transaction SMS alerts and ingest them into user's taste profile."""
    input_items: list[str | tuple[str, datetime | None]] = []
    if payload.sms_text:
        input_items.append(payload.sms_text)
    if payload.messages:
        input_items.extend(payload.messages)
    if payload.timestamped_messages:
        for t_msg in payload.timestamped_messages:
            input_items.append((t_msg.text, t_msg.received_at))

    if not input_items:
        raise HTTPException(status_code=400, detail="Must provide either sms_text, messages list, or timestamped_messages")

    parsed_transactions = parse_sms_batch(input_items, payload.user_id)
    if not parsed_transactions:
        return {
            "status": "no_transactions_found",
            "message": "Could not identify any valid debit payment alerts from the provided SMS text",
            "parsed_count": 0,
            "classified_food_count": 0,
        }

    ingest_res = await ingest_transactions(session, parsed_transactions)

    profile = None
    if rebuild_profile:
        profile = await build_taste_profile(session, payload.user_id)

    return {
        "status": "success",
        "user_id": payload.user_id,
        "sms_count": len(input_items),
        "parsed_transactions_count": len(parsed_transactions),
        "ingest_summary": ingest_res.model_dump(),
        "taste_profile": {
            "version": profile.version,
            "total_food_transactions": profile.total_food_transactions,
            "avg_spend": profile.avg_spend,
            "top_cuisines": profile.cuisine_affinities,
        } if profile else None,
    }


@router.post("/food-orders")
async def ingest_food_orders(
    payload: FoodOrdersBatchIn,
    rebuild_profile: bool = Query(True, description="Automatically recompute user taste profile"),
    session: AsyncSession = Depends(get_db),
):
    """Ingest direct order history from Swiggy, Zomato, or food delivery apps."""
    if not payload.orders:
        raise HTTPException(status_code=400, detail="Order list cannot be empty")

    now = datetime.now(timezone.utc)
    transactions: list[TransactionIn] = []
    for order in payload.orders:
        tx_time = order.order_time or now
        platform_name = order.platform or "Food App"
        dish_desc = f" ({', '.join(order.dish_names[:3])})" if order.dish_names else ""
        desc = f"{platform_name}: Ordered from {order.restaurant_name}{dish_desc}"

        transactions.append(
            TransactionIn(
                user_id=payload.user_id,
                transaction_time=tx_time,
                amount=order.amount,
                merchant_name=order.restaurant_name,
                mcc_code="5812",
                payment_app=platform_name,
                raw_description=desc,
            )
        )

    ingest_res = await ingest_transactions(session, transactions)

    profile = None
    if rebuild_profile:
        profile = await build_taste_profile(session, payload.user_id)

    return {
        "status": "success",
        "user_id": payload.user_id,
        "orders_count": len(payload.orders),
        "ingest_summary": ingest_res.model_dump(),
        "taste_profile": {
            "version": profile.version,
            "total_food_transactions": profile.total_food_transactions,
            "avg_spend": profile.avg_spend,
            "top_cuisines": profile.cuisine_affinities,
        } if profile else None,
    }


import re

MAX_STATEMENT_FILE_SIZE = 5 * 1024 * 1024  # 5MB limit
USER_ID_REGEX = re.compile(r"^[A-Za-z0-9_.-]{1,64}$")


@router.post("/statement")
async def ingest_bank_statement(
    user_id: str = Form(..., description="Target user ID"),
    file: UploadFile = File(..., description="Bank statement CSV file"),
    rebuild_profile: bool = Query(True, description="Automatically recompute user taste profile"),
    session: AsyncSession = Depends(get_db),
):
    """Upload and parse a bank statement CSV extract (HDFC, ICICI, SBI, Axis) to ingest dining transactions."""
    if not USER_ID_REGEX.match(user_id):
        raise HTTPException(status_code=400, detail="Invalid user_id format. Must be alphanumeric (1-64 characters).")

    if not file.filename or not (file.filename.endswith(".csv") or file.filename.endswith(".txt")):
        raise HTTPException(status_code=400, detail="Uploaded file must be a CSV or text file")

    # Read up to MAX_STATEMENT_FILE_SIZE + 1 bytes to prevent memory exhaustion
    raw_bytes = await file.read(MAX_STATEMENT_FILE_SIZE + 1)
    if len(raw_bytes) > MAX_STATEMENT_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum supported statement size is {MAX_STATEMENT_FILE_SIZE // (1024 * 1024)}MB."
        )
    try:
        content = raw_bytes.decode("utf-8")
    except UnicodeDecodeError:
        content = raw_bytes.decode("latin-1", errors="replace")

    parsed_transactions = parse_statement_csv(content, user_id)
    if not parsed_transactions:
        return {
            "status": "no_transactions_found",
            "message": "No debit transactions could be extracted from this statement",
            "parsed_count": 0,
            "classified_food_count": 0,
        }

    ingest_res = await ingest_transactions(session, parsed_transactions)

    profile = None
    if rebuild_profile:
        profile = await build_taste_profile(session, user_id)

    return {
        "status": "success",
        "user_id": user_id,
        "filename": file.filename,
        "parsed_transactions_count": len(parsed_transactions),
        "ingest_summary": ingest_res.model_dump(),
        "taste_profile": {
            "version": profile.version,
            "total_food_transactions": profile.total_food_transactions,
            "avg_spend": profile.avg_spend,
            "top_cuisines": profile.cuisine_affinities,
        } if profile else None,
    }


@router.post("/mock/generate")
async def generate_mock_data(
    persona: str = Query("south_indian_regular", description="south_indian_regular | cafe_hopper | budget_student"),
    days: int = Query(90, ge=7, le=365, description="Number of historical days to simulate"),
    session: AsyncSession = Depends(get_db),
):
    """Generate realistic synthetic UPI transactions for a selected persona and ingest them."""
    if persona not in PERSONA_PROFILES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid persona. Available: {list(PERSONA_PROFILES.keys())}",
        )

    mock_txs = generate_mock_transactions_for_persona(persona, days=days)
    ingest_res = await ingest_transactions(session, mock_txs)

    # Recompute taste profile for the affected user
    user_id = PERSONA_PROFILES[persona]["user_id"]
    profile = await build_taste_profile(session, user_id)

    return {
        "persona": persona,
        "user_id": user_id,
        "description": PERSONA_PROFILES[persona]["description"],
        "transactions_generated": len(mock_txs),
        "ingest_summary": ingest_res.model_dump(),
        "taste_profile_version": profile.version,
    }

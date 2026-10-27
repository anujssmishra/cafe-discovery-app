from datetime import datetime, timezone
from hashlib import sha256
from pydantic import ValidationError
from sqlalchemy import func, select
from fastapi import APIRouter, Depends, Query, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.transaction import (
    TransactionBatchIn, 
    TransactionIn,
    IngestResponse, 
    SmsIngestRequest,
    FoodOrdersBatchIn,
    PaymentsBatchIn,
    IngestOutcome,
)
from app.ingestion.pipeline import ingest_transactions
from app.ingestion.order_import import order_to_transaction, order_rejection, preview_food_orders
from app.ingestion.sms_parser import parse_sms, sms_to_transaction_in
from app.ingestion.statement_parser import parse_statement_csv
from app.profile.builder import build_taste_profile
from app.mock.transactions import generate_mock_transactions_for_persona, PERSONA_PROFILES
from app.models.profile import TasteProfile
from app.models.transaction import FoodPurchase

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


def _import_payload(result: IngestResponse, profile: TasteProfile | None = None) -> dict:
    return {
        "status": "success",
        "submitted_count": result.submitted_count,
        "ingested_count": result.ingested_count,
        "duplicate_count": result.duplicate_count,
        "rejected_count": result.rejected_count,
        "unresolved_count": result.unresolved_count,
        "outcomes": [outcome.model_dump() for outcome in result.outcomes],
        "taste_profile": {
            "version": profile.version,
            "total_food_transactions": profile.total_food_transactions,
            "avg_spend": profile.avg_spend,
            "top_cuisines": profile.cuisine_affinities,
        } if profile else None,
    }


async def _profile_after_import(session: AsyncSession, user_id: str, result: IngestResponse, rebuild: bool):
    if not rebuild:
        return None
    if result.ingested_count or user_id in result.affected_users:
        return await build_taste_profile(session, user_id)
    # Repair an interrupted post-commit profile build on retry, while leaving a current profile alone.
    profile = (await session.execute(select(TasteProfile).where(TasteProfile.user_id == user_id))).scalar_one_or_none()
    if result.duplicate_count:
        count = await session.scalar(select(func.count()).select_from(FoodPurchase).where(FoodPurchase.user_id == user_id))
        if profile is None or profile.total_food_transactions != count:
            return await build_taste_profile(session, user_id)
    return profile


@router.post("/payments")
async def ingest_structured_payments(
    payload: PaymentsBatchIn,
    rebuild_profile: bool = Query(True),
    session: AsyncSession = Depends(get_db),
):
    """Ingest the safe, versioned on-device payment contract without raw SMS text."""
    now = datetime.now(timezone.utc)
    transactions = [
        TransactionIn(
            user_id=payload.user_id,
            transaction_time=payment.transaction_time or now,
            time_precision=payment.time_precision,
            timezone=payment.timezone,
            merchant_name=payment.merchant_name,
            amount=payment.amount,
            upi_ref=payment.upi_ref,
            payment_app=payment.payment_app,
            source_id=payment.source_id,
            cuisine=payment.cuisine,
            dish_names=payment.dish_names,
            order_id=payment.order_id, order_platform=payment.order_platform,
            linked_transaction_id=payment.linked_transaction_id,
            order_status=payment.order_status, currency=payment.currency,
            mcc_code="5812",
            raw_description=f"Payment: Paid Rs {payment.amount:.2f} to {payment.merchant_name}",
        )
        for payment in payload.payments
    ]
    result = await ingest_transactions(session, transactions)
    profile = await _profile_after_import(session, payload.user_id, result, rebuild_profile)
    return _import_payload(result, profile)


@router.post("/sms")
async def ingest_sms_messages(
    payload: SmsIngestRequest,
    rebuild_profile: bool = Query(True, description="Automatically recompute user taste profile"),
    session: AsyncSession = Depends(get_db),
):
    """Legacy SMS input; returns honest per-message parse/import outcomes."""
    input_items: list[tuple[str, datetime | None]] = []
    if payload.sms_text:
        input_items.append((payload.sms_text, None))
    input_items.extend((text, None) for text in payload.messages or [])
    input_items.extend((message.text, message.received_at) for message in payload.timestamped_messages or [])
    if not input_items:
        raise HTTPException(status_code=400, detail="Must provide either sms_text, messages list, or timestamped_messages")

    transactions = []
    source_order = []
    rejected = []
    for text, received_at in input_items:
        source_id = "sms:" + sha256((text.strip() + (received_at.isoformat() if received_at else "")).encode()).hexdigest()
        source_order.append(source_id)
        try:
            parsed = parse_sms(text, received_at)
            transaction = sms_to_transaction_in(parsed, payload.user_id) if parsed else None
        except (ValidationError, ValueError):
            transaction = None
        if transaction is None:
            rejected.append(IngestOutcome(source_id=source_id, status="rejected", reason="not_a_supported_food_payment"))
        else:
            transactions.append(transaction)

    result = await ingest_transactions(session, transactions)
    # Restore original order, including repeated source IDs within this request.
    by_source: dict[str | None, list[IngestOutcome]] = {}
    for outcome in [*result.outcomes, *rejected]:
        by_source.setdefault(outcome.source_id, []).append(outcome)
    result.outcomes = [by_source[source_id].pop(0) for source_id in source_order]
    result.submitted_count = len(input_items)
    result.rejected_count += len(rejected)
    result.skipped_count += len(rejected)
    profile = await _profile_after_import(session, payload.user_id, result, rebuild_profile)
    response = _import_payload(result, profile)
    response.update({
        "user_id": payload.user_id, "sms_count": len(input_items),
        "parsed_count": len(transactions), "parsed_transactions_count": len(transactions),
        "classified_food_count": result.classified_food_count,
        "ingest_summary": result.model_dump(),
    })
    if not transactions:
        response.update(status="no_transactions_found", message="Could not identify any valid food payment alerts")
    return response


@router.post("/food-orders/preview")
async def preview_order_import(
    payload: FoodOrdersBatchIn, session: AsyncSession = Depends(get_db),
):
    """Show exact duplicates and user-owned review candidates without mutating history."""
    return await preview_food_orders(session, payload.user_id, payload.orders)


@router.post("/food-orders")
async def ingest_food_orders(
    payload: FoodOrdersBatchIn,
    rebuild_profile: bool = Query(True, description="Automatically recompute user taste profile"),
    session: AsyncSession = Depends(get_db),
):
    """Legacy structured orders, with safe order identity and enrichment when supplied."""
    transactions = []
    rejected_by_position = {}
    for position, order in enumerate(payload.orders):
        reason = order_rejection(order)
        if reason:
            rejected_by_position[position] = IngestOutcome(source_id=order.source_id, status="rejected", reason=reason)
        else:
            transactions.append(order_to_transaction(order, payload.user_id))
    result = await ingest_transactions(session, transactions)
    result.submitted_count += len(rejected_by_position)
    result.rejected_count += len(rejected_by_position)
    result.skipped_count += len(rejected_by_position)
    accepted_outcomes = iter(result.outcomes)
    result.outcomes = [
        rejected_by_position[position] if position in rejected_by_position else next(accepted_outcomes)
        for position in range(len(payload.orders))
    ]
    profile = await _profile_after_import(session, payload.user_id, result, rebuild_profile)
    response = _import_payload(result, profile)
    response.update(user_id=payload.user_id, orders_count=len(payload.orders), ingest_summary=result.model_dump())
    return response


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

    rejected: list[IngestOutcome] = []
    parsed_transactions = parse_statement_csv(content, user_id, rejections=rejected)
    result = await ingest_transactions(session, parsed_transactions)
    result.submitted_count += len(rejected)
    result.rejected_count += len(rejected)
    result.skipped_count += len(rejected)
    result.outcomes.extend(rejected)
    profile = await _profile_after_import(session, user_id, result, rebuild_profile)
    response = _import_payload(result, profile)
    response.update({
        "user_id": user_id, "filename": file.filename,
        "parsed_count": len(parsed_transactions),
        "parsed_transactions_count": len(parsed_transactions),
        "classified_food_count": result.classified_food_count,
        "ingest_summary": result.model_dump(),
    })
    if not parsed_transactions:
        response.update(status="no_transactions_found", message="No food debits could be extracted from this statement")
    return response


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

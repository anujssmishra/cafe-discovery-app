import asyncio
import hashlib
import json
from datetime import datetime
from pathlib import Path

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.models.base import Base
from app.models.profile import TasteProfile
from app.models.transaction import PaymentIdentity, UpiTransaction, FoodPurchase
from app.profile.builder import build_taste_profile


@pytest.mark.asyncio
async def test_legacy_duplicate_references_are_reconciled_without_deleting_history(client, db_session):
    for index, reference in enumerate([' 112233445566 ', '112233445566', None]):
        transaction = UpiTransaction(
            id=f'legacy-repeat-{index}', user_id='legacy_repeated', upi_ref=reference,
            amount=100, merchant_name='Synthetic Cafe', mcc_code='5812',
            transaction_time=datetime(2026, 10, 20, 8),
        )
        db_session.add(transaction)
        db_session.add(FoodPurchase(
            transaction_id=transaction.id, user_id=transaction.user_id,
            cuisine_detected='cafe_western', meal_type='breakfast', price_band='budget',
            day_of_week=1, hour_of_day=8, is_weekend=False, purchased_at=transaction.transaction_time,
        ))
    await db_session.commit()
    profile = (await client.get('/api/v1/profile/legacy_repeated')).json()
    ledger = (await client.get('/api/v1/profile/legacy_repeated/transactions')).json()
    assert profile['total_food_transactions'] == ledger['total_count'] == 2
    assert ledger['total_spent'] == 200
    assert await db_session.scalar(select(func.count()).select_from(UpiTransaction)) == 3


@pytest.mark.asyncio
async def test_unknown_time_remains_unknown_and_erasure_removes_identity_aliases(client, db_session):
    payload = {'schema_version': 1, 'user_id': 'unknown_time', 'payments': [{
        'source_id': 'unknown-clock', 'merchant_name': 'Synthetic Cafe',
        'amount': 125, 'upi_ref': '991122334455',
    }]}
    assert (await client.post('/api/v1/ingest/payments', json=payload)).json()['ingested_count'] == 1
    ledger = (await client.get('/api/v1/profile/unknown_time/transactions')).json()
    assert ledger['transactions'][0]['transaction_time'] is None
    assert ledger['transactions'][0]['time_precision'] == 'unknown'
    profile = (await client.get('/api/v1/profile/unknown_time')).json()
    assert profile['meal_patterns'] == {}
    assert profile['unresolved_transactions'] == 1
    assert await db_session.scalar(select(func.count()).select_from(PaymentIdentity)) >= 2
    assert (await client.delete('/api/v1/profile/unknown_time')).status_code == 200
    assert await db_session.scalar(select(func.count()).select_from(PaymentIdentity)) == 0
    assert (await client.post('/api/v1/ingest/payments', json=payload)).json()['ingested_count'] == 1


@pytest.mark.asyncio
async def test_two_workers_can_create_the_same_empty_profile(tmp_path):
    engine = create_async_engine(f'sqlite+aiosqlite:///{tmp_path / "profile-race.db"}')
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    async def build():
        async with sessions() as session:
            result = await build_taste_profile(session, 'concurrent_profile')
            return result.user_id, result.total_food_transactions
    assert await asyncio.gather(build(), build()) == [
        ('concurrent_profile', 0), ('concurrent_profile', 0),
    ]
    async with sessions() as session:
        assert await session.scalar(select(func.count()).select_from(TasteProfile)) == 1
    await engine.dispose()


def test_bundled_catalogue_matches_public_source_revision():
    root = Path(__file__).resolve().parents[2]
    source = root / 'php_app/schema/lucknow_cafes.sql'
    snapshot = json.loads((root / 'food_recsys/app/catalogue/cafes.json').read_text())
    assert snapshot['source_sha256'] == hashlib.sha256(source.read_bytes()).hexdigest()
    assert len(snapshot['restaurants']) == 32
    assert all(row['offerings'] and row['photo_url'] for row in snapshot['restaurants'])


@pytest.mark.asyncio
async def test_meal_explanation_uses_same_evidence_as_the_score(client):
    payments = [{
        'source_id': 'breakfast-only', 'merchant_name': 'Sagar Ratna', 'amount': 100,
        'cuisine': 'south_indian', 'transaction_time': '2026-10-20T08:00:00+05:30',
    }] + [{
        'source_id': f'dinner-{i}', 'merchant_name': 'Synthetic Pizza', 'amount': 900,
        'cuisine': 'pizza', 'transaction_time': f'2026-10-{i + 10:02}T20:00:00+05:30',
    } for i in range(9)]
    await client.post('/api/v1/ingest/payments', json={
        'schema_version': 1, 'user_id': 'explanation_scope', 'payments': payments,
    })
    result = (await client.get('/api/v1/recommend/explanation_scope?meal=breakfast&cuisine=south_indian')).json()
    first = result['recommendations'][0]
    assert first['score_breakdown']['cuisine_score'] == 1
    assert any('100% of orders with identified cuisine' in reason for reason in first['reasons'])
    assert any('avg ₹100/order' in reason for reason in first['reasons'])

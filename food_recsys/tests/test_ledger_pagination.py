import base64
import json
from datetime import datetime

import pytest

from app.models.transaction import FoodPurchase, UpiTransaction


async def add_ledger_records(session, user_id, count, *, prefix='ledger', amount=100.25):
    for index in range(count):
        identifier = f'{prefix}-{index:04d}'
        transaction = UpiTransaction(
            id=identifier, user_id=user_id, transaction_time=datetime(2026, 10, 26, 8, 30),
            amount=amount, merchant_name=f'Synthetic dining merchant {index}', mcc_code='5812',
        )
        session.add(transaction)
        session.add(FoodPurchase(
            transaction_id=identifier, user_id=user_id, cuisine_detected='unspecified',
            meal_type='unknown', price_band='moderate', day_of_week=0, hour_of_day=8,
            is_weekend=False, purchased_at=transaction.transaction_time,
        ))
    await session.commit()


@pytest.mark.asyncio
async def test_251_records_have_whole_ledger_totals_and_no_tied_time_duplicates(client, db_session):
    await add_ledger_records(db_session, 'ledger_user', 251)
    await add_ledger_records(db_session, 'other_user', 1, prefix='other', amount=9999)
    db_session.add(UpiTransaction(id='non-food', user_id='ledger_user',
                                  transaction_time=datetime(2026, 10, 27), amount=5000,
                                  merchant_name='Synthetic non-food payment', mcc_code='5411'))
    await db_session.commit()

    loaded = []
    cursor = None
    page_sizes = []
    while True:
        params = {'limit': 100}
        if cursor:
            params['cursor'] = cursor
        response = await client.get('/api/v1/profile/ledger_user/transactions', params=params)
        assert response.status_code == 200
        page = response.json()
        assert page['total_count'] == 251
        assert page['total_spent'] == 25162.75
        assert page['user_id'] == 'ledger_user'
        page_sizes.append(len(page['transactions']))
        loaded.extend(page['transactions'])
        if not page['has_more']:
            assert page['next_cursor'] is None
            break
        assert page['next_cursor'] and page['next_cursor'] != cursor
        cursor = page['next_cursor']
        assert len(page_sizes) <= 3

    assert page_sizes == [100, 100, 51]
    assert [row['id'] for row in loaded] == [f'ledger-{index:04d}' for index in reversed(range(251))]
    assert len({row['id'] for row in loaded}) == 251
    assert all(row['classification_status'] == 'unresolved' for row in loaded)
    assert all(row['meal_type'] == 'unknown' for row in loaded)
    assert all(datetime.fromisoformat(row['transaction_time']).tzinfo is not None for row in loaded)
    profile = await client.get('/api/v1/profile/ledger_user')
    assert profile.json()['total_food_transactions'] == 251


@pytest.mark.asyncio
async def test_cursor_from_another_user_never_exposes_their_records_or_totals(client, db_session):
    await add_ledger_records(db_session, 'first_user', 2, prefix='z-first', amount=100)
    await add_ledger_records(db_session, 'second_user', 2, prefix='a-second', amount=250)
    first = (await client.get('/api/v1/profile/first_user/transactions', params={'limit': 1})).json()
    response = await client.get('/api/v1/profile/second_user/transactions', params={
        'limit': 100, 'cursor': first['next_cursor'],
    })
    assert response.status_code == 200
    second = response.json()
    assert second['total_count'] == 2
    assert second['total_spent'] == 500
    assert len(second['transactions']) == 2
    assert all(row['id'].startswith('a-second') for row in second['transactions'])


@pytest.mark.asyncio
@pytest.mark.parametrize('cursor', ['a', 'not-base64!!', 'W10', 'bnVsbA', 'WzEsMl0'])
async def test_malformed_ledger_cursors_return_validation_error(client, cursor):
    response = await client.get('/api/v1/profile/ledger_user/transactions', params={'cursor': cursor})
    assert response.status_code == 400
    assert response.json()['detail'] == 'Invalid ledger cursor'


@pytest.mark.asyncio
async def test_timezone_equivalent_cursor_and_empty_ledger(client, db_session):
    await add_ledger_records(db_session, 'ledger_user', 2)
    token = base64.urlsafe_b64encode(json.dumps(
        ['2026-10-26T14:00:00+05:30', 'ledger-0001']).encode()).decode().rstrip('=')
    response = await client.get('/api/v1/profile/ledger_user/transactions', params={'cursor': token})
    assert response.status_code == 200
    assert [row['id'] for row in response.json()['transactions']] == ['ledger-0000']
    empty = (await client.get('/api/v1/profile/no_history/transactions')).json()
    assert empty['total_count'] == 0
    assert empty['total_spent'] == 0
    assert empty['transactions'] == []
    assert empty['has_more'] is False
    assert empty['next_cursor'] is None

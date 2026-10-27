from types import SimpleNamespace

import pytest

from app.models.restaurant import Restaurant
from app.recsys.explainer import explain_recommendation
from app.schemas.recommendation import ScoreBreakdown


@pytest.mark.asyncio
async def test_breakfast_and_dinner_use_local_meal_history_for_ranking(client, db_session):
    db_session.add_all([
        Restaurant(id='qa-south', name='Synthetic South Kitchen', city='Test City', area='Meal QA',
                   cuisines=['south_indian'], price_band='moderate', source='manual', avg_rating=4),
        Restaurant(id='qa-pizza', name='Synthetic Pizza Kitchen', city='Test City', area='Meal QA',
                   cuisines=['pizza'], price_band='moderate', source='manual', avg_rating=4),
    ])
    await db_session.commit()
    payments = []
    for day in [20, 21, 22]:
        payments.extend([
            {'source_id': f'breakfast-{day}', 'merchant_name': 'Synthetic South Kitchen',
             'amount': 400, 'transaction_time': f'2026-10-{day}T08:15:00+05:30',
             'timezone': 'Asia/Kolkata', 'cuisine': 'south_indian'},
            {'source_id': f'dinner-{day}', 'merchant_name': 'Synthetic Pizza Kitchen',
             'amount': 400, 'transaction_time': f'2026-10-{day}T20:15:00+05:30',
             'timezone': 'Asia/Kolkata', 'cuisine': 'pizza'},
        ])
    imported = await client.post('/api/v1/ingest/payments', json={
        'schema_version': 1, 'user_id': 'meal_user', 'payments': payments,
    })
    assert imported.status_code == 200
    assert imported.json()['ingested_count'] == 6

    breakfast = await client.get('/api/v1/recommend/meal_user', params={'meal': 'breakfast', 'area': 'Meal QA', 'n': 2})
    dinner = await client.get('/api/v1/recommend/meal_user', params={'meal': 'dinner', 'area': 'Meal QA', 'n': 2})
    assert breakfast.status_code == dinner.status_code == 200
    assert breakfast.json()['recommendations'][0]['restaurant']['id'] == 'qa-south'
    assert dinner.json()['recommendations'][0]['restaurant']['id'] == 'qa-pizza'
    assert breakfast.json()['recommendations'][0]['score_breakdown']['cuisine_score'] == 1
    assert dinner.json()['recommendations'][0]['score_breakdown']['cuisine_score'] == 1
    assert 'recorded breakfast preferences' in breakfast.json()['context_message']
    assert 'recorded dinner preferences' in dinner.json()['context_message']
    profile = (await client.get('/api/v1/profile/meal_user')).json()
    assert profile['meal_patterns']['breakfast'] == {'weekday': 3, 'weekend': 0}
    assert profile['meal_patterns']['dinner'] == {'weekday': 3, 'weekend': 0}

    overall = (await client.get('/api/v1/recommend/meal_user', params={'area': 'Meal QA', 'n': 2})).json()
    lunch = (await client.get('/api/v1/recommend/meal_user', params={'meal': 'lunch', 'area': 'Meal QA', 'n': 2})).json()
    assert 'No recorded lunch history' in lunch['context_message']
    assert [(row['restaurant']['id'], row['score']) for row in lunch['recommendations']] == [
        (row['restaurant']['id'], row['score']) for row in overall['recommendations']]


@pytest.mark.asyncio
async def test_cold_start_meal_context_explains_fallback(client):
    response = await client.get('/api/v1/recommend/new_meal_user', params={'meal': 'late_night', 'n': 2})
    assert response.status_code == 200
    data = response.json()
    assert data['count'] == 2
    assert data['meal_context'] == 'late_night'
    assert 'No recorded late night history' in data['context_message']
    assert 'overall matches' in data['context_message']


@pytest.mark.parametrize('affinities', [
    {'south_indian': 0.6, 'pizza': 0.4},
    {'south_indian': 0.5, 'pizza': 0.5},
])
def test_secondary_or_tied_cuisine_is_not_claimed_as_number_one_or_spending_share(affinities):
    profile = SimpleNamespace(
        cuisine_affinities=affinities, cuisine_spending_share={'south_indian': 0.1, 'pizza': 0.9},
        price_distribution={'moderate': 1}, avg_spend=250, top_restaurants={},
        meal_patterns={}, frequent_areas={},
    )
    restaurant = SimpleNamespace(id='pizza', cuisines=['pizza'], price_band='moderate', area='Test area')
    score = ScoreBreakdown(cuisine_score=0.4, price_score=1, novelty_score=1, geo_score=0.5, total_score=0.7)
    cuisine_reason = explain_recommendation(profile, restaurant, score)[0]
    assert '#1' not in cuisine_reason
    assert 'most frequent' not in cuisine_reason
    assert f"{round(affinities['pizza'] * 100)}%" in cuisine_reason
    assert 'orders with identified cuisine' in cuisine_reason
    assert 'spending' not in cuisine_reason

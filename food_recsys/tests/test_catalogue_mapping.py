import pytest
from sqlalchemy import func, select

from app.catalogue.sync import sync_public_catalogue
from app.models.restaurant import Restaurant


@pytest.mark.asyncio
async def test_cuisine_filter_precedes_limit_and_offset(client, db_session):
    db_session.add_all([
        Restaurant(id='mapping-a', name='A unrelated cafe', city='Test City', area='Mapping QA',
                   cuisines=['bakery'], price_band='moderate', source='manual'),
        Restaurant(id='mapping-z1', name='Z South Kitchen One', city='Test City', area='Mapping QA',
                   cuisines=['south_indian'], price_band='moderate', source='manual'),
        Restaurant(id='mapping-z2', name='Z South Kitchen Two', city='Test City', area='Mapping QA',
                   cuisines=['south_indian'], price_band='moderate', source='manual'),
    ])
    await db_session.commit()

    first = await client.get('/api/v1/restaurants', params={
        'area': 'Mapping QA', 'cuisine': 'south_indian', 'limit': 1,
    })
    second = await client.get('/api/v1/restaurants', params={
        'area': 'Mapping QA', 'cuisine': 'south_indian', 'limit': 1, 'offset': 1,
    })
    assert first.status_code == second.status_code == 200
    assert [row['id'] for row in first.json()] == ['mapping-z1']
    assert [row['id'] for row in second.json()] == ['mapping-z2']


@pytest.mark.asyncio
async def test_metadata_includes_all_catalogue_areas_and_excludes_inactive(client, db_session):
    db_session.add(Restaurant(id='inactive-metadata', name='Closed example', city='Test City',
                              area='Closed area', cuisines=['closed_cuisine'], is_active=False))
    await db_session.commit()
    response = await client.get('/api/v1/restaurants/metadata')
    assert response.status_code == 200
    data = response.json()
    assert set(data['areas']) == {
        'Aliganj', 'Aminabad', 'Badshahnagar', 'Cantonment', 'Chowk', 'Gomti Nagar',
        'Hazratganj', 'Indira Nagar', 'Mall Avenue', 'Nirala Nagar', 'Sushant Golf City',
    }
    assert 'late_night' in data['meal_options']
    assert 'south_indian' in data['cuisines']
    assert 'closed_cuisine' not in data['cuisines']
    assert (await client.get('/api/v1/restaurants/inactive-metadata')).status_code == 404


def public_cafe(**overrides):
    return {
        'id': 'f0000000-0000-0000-0000-000000000001',
        'name': 'Synthetic public cafe', 'city': 'Test City', 'area': 'Original area',
        'address': '1 Example Street', 'price_band': 'moderate', 'is_active': True,
        'cuisines': ['bakery'], 'source': 'cafe_app',
        'photo_url': 'https://example.com/photo.jpg',
        'hero_image_url': 'https://example.com/hero.jpg',
        'website': 'https://example.com/cafe',
        'vibe_tags': ['Quiet seating'], 'food_highlights': ['Sourdough'],
        'offerings': [{'drink_type': 'Coffee', 'brewing_method': 'Pour over',
                      'price': None, 'currency': 'INR', 'checked_on': '2026-10-20',
                      'source': 'Synthetic menu'}],
        'checked_on': '2026-10-20',
        **overrides,
    }


@pytest.mark.asyncio
async def test_public_sync_preserves_uuid_updates_details_and_propagates_closure(client, db_session):
    cafe = public_cafe(private_notes='Must never become public', member_email='private@example.test')
    await sync_public_catalogue(db_session, {'schema_version': 1, 'restaurants': [cafe]})
    response = await client.get(f"/api/v1/restaurants/{cafe['id']}")
    assert response.status_code == 200
    details = response.json()
    for field in ['photo_url', 'hero_image_url', 'website', 'vibe_tags', 'food_highlights', 'offerings', 'checked_on']:
        assert details[field] == cafe[field]
    assert 'private_notes' not in details
    assert 'member_email' not in details

    changed = public_cafe(name='Synthetic renamed cafe', area='Changed area',
                          address='2 Example Street', price_band='premium', is_active=False)
    await sync_public_catalogue(db_session, {'schema_version': 1, 'restaurants': [changed]})
    restaurant = await db_session.get(Restaurant, cafe['id'])
    assert restaurant.id == cafe['id']
    assert restaurant.name == 'Synthetic renamed cafe'
    assert restaurant.area == 'Changed area'
    assert restaurant.address == '2 Example Street'
    assert restaurant.price_band == 'premium'
    assert restaurant.is_active is False
    assert await db_session.scalar(select(func.count()).select_from(Restaurant).where(Restaurant.id == cafe['id'])) == 1
    assert (await client.get(f"/api/v1/restaurants/{cafe['id']}")).status_code == 404
    assert 'Changed area' not in (await client.get('/api/v1/restaurants/metadata')).json()['areas']
    # A partial export must leave unrelated manually curated catalogue records intact.
    assert await db_session.scalar(select(func.count()).select_from(Restaurant).where(Restaurant.source == 'manual')) == 48


@pytest.mark.asyncio
async def test_sync_retains_cuisine_enrichment_if_source_has_no_taxonomy(db_session):
    cafe = public_cafe()
    await sync_public_catalogue(db_session, {'schema_version': 1, 'restaurants': [cafe]})
    without_cuisine = {key: value for key, value in public_cafe(address='Updated address').items() if key != 'cuisines'}
    await sync_public_catalogue(db_session, {'schema_version': 1, 'restaurants': [without_cuisine]})
    assert (await db_session.get(Restaurant, cafe['id'])).cuisines == ['bakery']
    await sync_public_catalogue(db_session, {'schema_version': 1, 'restaurants': [public_cafe(cuisines=[])]})
    assert (await db_session.get(Restaurant, cafe['id'])).cuisines == []


@pytest.mark.asyncio
async def test_duplicate_ids_rejected_before_importing_any_rows(db_session):
    cafe = public_cafe()
    with pytest.raises(ValueError, match='duplicate restaurant IDs'):
        await sync_public_catalogue(db_session, {'schema_version': 1, 'restaurants': [cafe, cafe]})
    assert await db_session.get(Restaurant, cafe['id']) is None

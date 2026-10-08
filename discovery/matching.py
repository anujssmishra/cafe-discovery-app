from decimal import Decimal


def rank_cafes(cafes, preferences):
    if not preferences:
        return cafes, False

    essential_amenities = preferences.get("essential_amenities", [])
    preferred_amenities = preferences.get("preferred_amenities", [])
    drink = preferences.get("drink", "")
    budget_str = preferences.get("budget", "")
    budget = Decimal(budget_str) if budget_str else None

    # Global active dimensions based on preferences
    global_use_T = bool(drink)
    global_use_P = bool(preferred_amenities)
    global_use_B = bool(budget and drink)

    from cafes.models import CafeObservation

    amenity_choices = dict(CafeObservation.Attribute.choices)

    eligible = []
    unmet_summary = {}

    for cafe in cafes:
        # 1. Eligibility Check
        failed_essentials = []
        for req in essential_amenities:
            obs = next((o for o in cafe.observations.all() if o.attribute == req), None)
            if not obs or not obs.is_current or obs.value != "yes":
                failed_essentials.append(req)

        if failed_essentials:
            for req in failed_essentials:
                reason = f"Missing essential amenity: {amenity_choices.get(req, req)}"
                unmet_summary[reason] = unmet_summary.get(reason, 0) + 1
            continue

        cafe_drink_prices = []
        if global_use_B:
            offerings = [
                o
                for o in cafe.offerings.all()
                if o.drink_type == drink and o.is_current and o.price is not None
            ]
            if not offerings:
                reason = "Missing price or drink not available"
                unmet_summary[reason] = unmet_summary.get(reason, 0) + 1
                continue  # Unknown pricing or drink not available (fails hard budget)

            min_price = min(o.price for o in offerings)
            if min_price > budget * Decimal("1.2"):
                reason = "Exceeds hard budget ceiling"
                unmet_summary[reason] = unmet_summary.get(reason, 0) + 1
                continue  # Hard ceiling fails
            cafe_drink_prices.append(min_price)
        elif global_use_T:
            # If no budget, but drink specified, is drink availability a hard constraint?
            # "T — taste: proportion of the selected drink/brewing preferences supported by the café's checked offerings."
            # If 0, maybe it just gets a 0 score. We'll leave it in.
            pass

        # 2. Score Calculation (Per-cafe weights)
        weight_T = 4.0
        weight_P = 3.0
        weight_B = 2.0

        T_score = 0.0
        T_active = False
        if global_use_T:
            offerings = [o for o in cafe.offerings.all() if o.drink_type == drink and o.is_current]
            if offerings:
                T_score = 1.0
                T_active = True
            else:
                # Known absent? If there are any current offerings but not this one, we assume absent.
                has_current = any(o.is_current for o in cafe.offerings.all())
                if has_current:
                    T_score = 0.0
                    T_active = True
                else:
                    # Entire dimension unknown
                    T_active = False

        P_score = 0.0
        P_active = False
        if global_use_P:
            present = 0
            known = 0
            for req in preferred_amenities:
                obs = next((o for o in cafe.observations.all() if o.attribute == req), None)
                if obs and obs.is_current:
                    if obs.value == "yes":
                        present += 1
                        known += 1
                    elif obs.value == "no":
                        known += 1

            if known > 0:
                P_score = present / known
                P_active = True
            else:
                P_active = False

        B_score = 0.0
        B_active = False
        if global_use_B and cafe_drink_prices:
            min_price = cafe_drink_prices[0]
            if min_price <= budget:
                B_score = 1.0
            elif min_price <= budget * Decimal("1.2"):
                B_score = 0.5
            else:
                B_score = 0.0
            B_active = True

        total_weight = sum(
            [weight_T if T_active else 0, weight_P if P_active else 0, weight_B if B_active else 0]
        )

        final_score = 0.0
        if total_weight > 0:
            final_score = (
                (T_score * weight_T if T_active else 0)
                + (P_score * weight_P if P_active else 0)
                + (B_score * weight_B if B_active else 0)
            ) / total_weight

        # 3. Evidence coverage and explanations
        coverage = 0
        explanation_parts = []
        if T_active and T_score > 0:
            coverage += 1
            drink_name = dict(cafe.offerings.model.DrinkType.choices).get(drink, drink)
            explanation_parts.append(f"Serves {drink_name}")
        if B_active and B_score > 0:
            coverage += 1
            explanation_parts.append("Price fits budget")
        if P_active and P_score > 0:
            # present count is known here implicitly, let's just count
            present = sum(
                1
                for req in preferred_amenities
                if any(
                    o.attribute == req and o.is_current and o.value == "yes"
                    for o in cafe.observations.all()
                )
            )
            coverage += present
            explanation_parts.append(f"Has {present} preferred amenities")

        explanation = (
            ", ".join(explanation_parts)
            if explanation_parts
            else "No specific match reasons found."
        )

        cafe.match_score = final_score
        cafe.match_coverage = coverage
        cafe.match_explanation = explanation
        eligible.append(cafe)

    eligible.sort(key=lambda c: (-c.match_score, -c.match_coverage, c.id))

    has_active_prefs = global_use_T or global_use_B or global_use_P or bool(essential_amenities)

    if len(eligible) == 0 and has_active_prefs:
        return eligible, unmet_summary
    return eligible, None

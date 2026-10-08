# Project Brief

Last updated: 2026-10-07. Status: first local catalogue increment implemented for review; customer validation and the hosted pilot have not started. See [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) for current evidence.

## 1. The Idea

Build a personalized café-discovery app that helps a person find a café suited to both their taste and today's purpose. The app combines what the person likes to drink, what they intend to do, their budget and location, and the café's verified characteristics. As the community grows, consenting users' repeat visits can add a behavioural signal.

The internal analogy is “Spotify for cafés”: learn preferences and make relevant discoveries. The actual product promise is **“Find your kind of coffee. Find your kind of café.”** The brand and app name have not been selected.

The product also includes geographic browsing and an original curated café journal: map/list search, area shortcuts, detail dialogs, directions, coffee/experience notes and a separate trip-value assessment. These additions are specified in [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md). They provide context for discovery while taste and purpose remain the personalization basis.

## 2. The Customer Problem

A single average rating combines people with different tastes and reasons for visiting. A popular café can still be unsuitable for someone who wants a quiet work session, a specific brewing method, a place for a date, or an affordable daily coffee.

The problem hypothesis is that customers spend too much effort checking menus, photos, recommendations, and amenities, and still experience poor matches. This is a hypothesis to validate through recent examples of real café visits, not an established market finding.

## 3. Initial Customers

| Segment | Decision they need help with | Relevant signals |
|---|---|---|
| Coffee enthusiasts | Where can I find a drink or brewing style I enjoy? | Drink types, brewing methods, roast preferences where known |
| Students and people working from cafés | Where can I comfortably spend time? | Quietness, seating, Wi-Fi, charging, laptop policy |
| People meeting friends or going on dates | Which setting fits this visit? | Ambience, group seating, outdoor space, price range |
| People exploring a new area | What is likely to suit me nearby? | Taste profile, travel radius, reliable café details |

Choose one primary segment for the first pilot. Supporting several purposes in the product does not require recruiting every segment at once.

## 4. Why the Recommendation Could Be Better

The intended advantage is a combination of **taste, purpose, evidence, and explanation**. A recommendation should say which preferences it matches, what information is confirmed, and what remains unknown. Community claims must come from real, consenting participants and sufficient independent evidence.

Repeat visits can indicate satisfaction, but can also reflect proximity, convenience, price, or habit. Therefore, use short explicit feedback alongside visit logs. Do not treat frequent visits as proof of coffee quality or fabricate a confidence percentage.

## 5. How the Product Works

1. A person chooses drinks, budget, atmosphere, and today's purpose.
2. The app filters cafés by the person's location or selected area and any essential requirements, displaying the same eligible cafés on a map and list.
3. It ranks eligible cafés using known attributes, with a content-based fallback for new users.
4. Each recommendation explains its strongest relevant reasons. A detail page/dialog adds checked facts, attributed curator opinions and an optional external directions link.
5. The person saves a café or visits it and optionally records whether they would return.
6. Feedback supports matching evaluation and suggested preference updates; shared signals are used only under the data policy.

Example explanation: “Matches your preference for pour-over and quiet seating; its menu and amenities were checked on the date shown.” A statement about other people's visits is shown only when supported by recorded evidence.

## 6. Validation Before a Full Build

Proposed initial research: **15–20 café visitors and 5 café managers**, followed by a small manual recommendation experiment. These are research targets, not completed interviews.

Ask visitors about their last three café choices: where they went, why, what they checked, what disappointed them, and whether they returned. Ask them to show the decision process rather than only asking whether they like the idea. Avoid leading questions such as “Would you use an AI café app?”

Ask managers which drink and amenity details change, how they handle laptop use or long visits, whether they can maintain accurate information, and which referrals would be valuable. Obtain permission before recording interviews or using identifiable quotations.

For the manual test, collect a short preference form, recommend three cafés from a checked catalogue, and compare the person's response with a simple nearby-cafés list. Record reasons for preference, actual choices when voluntarily reported, and data gaps. Do not interpret a small convenience sample as proof of market demand.

## 7. Business Model Candidates

| Candidate | What would be sold | Evidence needed before adopting it |
|---|---|---|
| Referral partnerships | Agreed, attributable café referrals or offers | Café willingness to pay and reliable attribution |
| Coffee events | Discovery or referral for tastings and workshops | Demand, partner availability, and responsibility for bookings |
| Premium discovery | Features beyond a useful free discovery experience | Repeated use and demonstrated willingness to pay |
| Sponsored listings | Clearly labelled promotional placement | Advertiser demand without compromising organic ranking |

Begin with a free pilot. Pricing and the first revenue channel are unresolved. Organic ranking should remain based on user fit; advertising should be visibly separate. Do not sell identifiable taste profiles or visit histories.

## 8. Early Distribution

Recruit participants through relevant local coffee communities and participating cafés. Obtain each partner's approval for any poster, QR code, offer, or use of its logo. Track which recruitment channel produces useful feedback and returning users. No cafés have been contacted or enrolled through this repository.

## 9. Questions That Must Be Answered

- Which primary segment has the strongest recurring problem?
- Which pilot area has enough cafés and reachable participants?
- Will users contribute visit feedback often enough to support matching?
- Which attributes actually predict a satisfactory café visit?
- Can café information stay current with a small team?
- Does personalization outperform a simpler location-and-purpose filter?
- Who would pay, for what result, and at what price?

## 10. Reading Next

Use [GETTING_STARTED.md](GETTING_STARTED.md) for the first actions, [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) for product scope, and [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md) for the proposed plan. Record decisions in [DECISIONS.md](DECISIONS.md).

# Decisions, Assumptions and Open Questions

Last updated: 2026-10-06. Use this file as the handover record. A documented proposal is not automatically an approved decision or implemented feature.

## 1. Status Definitions

- **Confirmed:** the project direction or repository action is explicitly established.
- **Proposed:** a suggested starting choice to review before implementation or spending.
- **Open:** an answer, owner or evidence is still needed.
- **Implemented:** use only when actual code/operations and validation support it. No application decision below is currently marked implemented.

## 2. Confirmed Direction

| ID | Decision | Reason / evidence | Status |
|---|---|---|---|
| D01 | Scope is café discovery, rather than restaurant operations | Project owner's requested café adaptation | Confirmed |
| D02 | Personalization uses taste and visit purpose, with repeat behaviour as a potential later signal | Established concept in the project brief; usefulness still needs validation | Confirmed concept |
| D03 | Keep project documentation in the existing private GitHub repository | Repository created under anujssmishra; owner requested uploads | Confirmed repository arrangement |
| D04 | Use multiple connected Markdown documents with README as the entry point | Owner requested enough context for future readers and permitted multiple files | Confirmed documentation format |

## 3. Proposed Starting Choices

| ID | Proposal | Reason | Review trigger |
|---|---|---|---|
| P01 | One area, 20–30 checked cafés, 30–50 adult pilot participants | Manageable data and support burden | After research/accessibility of recruitment is known |
| P02 | Responsive web before native apps | Faster single-product validation | After web usage and retention evidence |
| P03 | Python 3.13, Django 5.2 LTS, default auth plus profile | Simple framework-supported foundation | Before coding; when versions/support change |
| P04 | SQLite only for local skeleton, PostgreSQL for hosted pilot | Durable multi-user operations | Before database and host selection |
| P05 | Content baseline first; optional 0.10 community repeat weight | Cold start without fabricated community evidence | After manual comparisons and real eligible data |
| P06 | Five eligible peers, 90-day window, one vote per peer | Limit dominance and disclosure risk | Privacy review and observed signal reliability |
| P07 | No GPS requirement, payment imports, banking access or LLM dependency | Core matching can be tested without these systems | Only for a separately justified feature |
| P08 | Private histories and separate community opt-in | Purpose control and understandable participation | Before collection; whenever data use changes |
| P09 | Free invited pilot; no selected revenue model | First establish usefulness and willingness to pay | After pilot/revenue interviews |
| P10 | Proposed effort 200–305 hours before contingency | Initial planning for specified scope | After manual test and foundation work |
| P11 | Proposed service reserve ₹2,000–₹5,000 per month | Budget conversation starting point, not quotes | Actual provider selection and spending approval |

Detailed scoring thresholds, retention targets and release criteria remain proposals in their respective files. The owner can change them; update all affected documents together and retain the reason.

## 4. Open Decisions Before Work or Launch

| Question | Needed by | Suggested accountable role | Current answer |
|---|---|---|---|
| Which city/neighbourhood and primary segment? | Research start | Product owner | Open |
| Who owns product decisions and weekly coordination? | Work start | Repository owner | Open |
| Who develops, checks data, and handles support? | Work planning | Product owner | Open |
| How many hours/week and what cash ceiling? | Scheduling/purchases | Product owner | Open |
| What is the product name and any domain? | Public communication | Product owner | Open |
| Which café sources and image rights are usable? | Data collection | Catalogue lead | Open |
| What feedback shows enough value to build/continue? | Manual test | Product owner/research lead | Proposed metrics need confirmation |
| Which host/database/email providers and regions? | Hosted pilot | Developer/data owner | Open |
| Which notices, retention, eligibility and legal requirements apply? | Participant collection/launch | Data owner with suitable review | Open |
| Who is the support/data/security contact? | Pilot recruitment | Operations owner | Open |
| What licence and contributor ownership arrangements apply? | External contribution/public release | Repository owner | Open |
| Which revenue hypothesis will be tested first? | Commercial experiment | Product owner | Open |

Selecting an accountable role is not the same as assigning a named person. Fill the person, date and decision before depending on it. None of these blanks prevents reading the project or carrying out a documentation review.

## 5. Risks and Experiments

| Risk / assumption | Current mitigation | Evidence to collect |
|---|---|---|
| Too little data for collaborative matching | Content-only baseline and transparent fallback | Number of eligible distinct contributors per café |
| Repeat visits mostly reflect convenience | Combine structured satisfaction and purpose; cap individual influence | Interview reasons and baseline comparisons |
| Café attributes become stale | Provenance, dates, reports and regular checks | Error rate and maintenance hours |
| A generic filter is already sufficient | Compare personalization against a simple list | Actual choices and usefulness responses |
| Users rarely submit visits | Keep discovery useful without logs | Contribution rate and observed form friction |
| Low return use | Choose a recurring segment and inspect failed matches | 14-day return plus qualitative reasons |
| Small cohorts reveal personal patterns | Opt-in, minimum aggregate threshold, private histories and rate limits | Privacy review and adversarial query testing |
| Hosting/cash plan is unrealistic | Durable database and cost review before purchase | Complete quotes and actual monthly usage |
| Scope expands into restaurant software | Maintain café-first pilot acceptance criteria | Every proposed addition has a distinct user need |

## 6. Decision Record Template

```markdown
ID and date:
Status: proposed / confirmed / superseded / implemented
Decision and owner:
Problem / evidence:
Alternatives considered:
Consequences and affected files:
Validation / implementation evidence:
Review trigger:
```

When superseding a material choice, preserve its reason and link to the replacement. Avoid leaving incompatible instructions in different files.

## 7. Documentation History

- Initial repository: private café concept README uploaded; no application code.
- 2026-10-06: expanded into a ten-file planning and startup guide, with explicit proposed scope, setup, design, data operations, roadmap, budget and contribution rules. This entry records documentation work, not completion of the product milestones.

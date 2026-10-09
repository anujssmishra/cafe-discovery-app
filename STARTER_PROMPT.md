# Starter Prompt for Any Coding Assistant

Read the current branch/head before using this prompt. Use the PHP fixes integrated from `fix/php-catalogue-review` on main; inspect Git rather than assuming a live agent session or recorded hash.

```text
Continue the existing private cafe-discovery-app repository.

Read AGENTS.md and DEVELOPMENT_HANDOFF.md, inspect Git status/head/remotes and preserve current work. The active application is php_app/ on PHP 8.2/MySQL; legacy_django/ is reference only. Do not scaffold a replacement or run Django setup commands.

Read GETTING_STARTED.md, DECISIONS.md, TECHNICAL_DESIGN.md, PRODUCT_BACKLOG.md and QUALITY_REVIEW.md for the selected work. Reproduce the PHP lint, unit and disposable local MySQL integration checks. Treat historical Django and earlier CI results separately from current PHP results.

Complete the next bounded task in the handoff: check the remaining interactive keyboard/narrow-screen acceptance, then address a separately selected backlog task. Fix any reproducible defects and update actual evidence. Use distinct backend/data, frontend/routing and QA ownership if delegation is useful; root owns configuration, integration and final docs. Do not overlap edits. Hostinger remains an unverified target; do not deploy without authorization.

Preserve café URLs, unrelated data, sources and historical dates. Unknown facts remain unknown, fictional fixtures must be labelled, and seeds require explicit local demo safeguards. There is no PHP admin, account, matching, map or ratings implementation yet.

Keep the repository private. Do not deploy, merge, seed production, create accounts, spend money or contact other people. Report prioritized defects/fixes, exact test results, branch/revision, remaining work and reproducible startup commands. Do not mark unverified criteria Done or implement later features automatically.
```

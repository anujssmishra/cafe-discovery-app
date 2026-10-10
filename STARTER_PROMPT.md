# Starter Prompt for Any Coding Assistant

Open this repository on `feat/sprint-1-catalogue`, then paste the text below into Codex, Claude, Gemini or another coding tool that can read the checkout. This is a suggested next task; it does not itself launch agents or transfer a chat.

```text
Continue my existing café discovery app in anujssmishra/cafe-discovery-app.

Read AGENTS.md and DEVELOPMENT_HANDOFF.md first. Inspect the actual Git state and preserve my changes. Use feat/sprint-1-catalogue as the integration baseline; main has not yet received the implementation at the handoff checkpoint. Do not create a replacement project.

Follow GETTING_STARTED.md to run the Django catalogue. Review PRODUCT_BACKLOG.md and QUALITY_REVIEW.md. Your first work package is to finish the remaining Sprint 1 browser, narrow-screen/mobile-layout and keyboard review, fix any observed defects, and record the exact checks you performed. Reproduce relevant automated checks, keeping previous 49-test/CI results separate from new results. Do not mark unverified acceptance criteria Done.

Use the existing source, design and data rules. Keep fictional records clearly labelled; unknown facts and unanswered ratings must stay unknown. Keep the repo private and leave deployment, spending and public release decisions for their authorized scope.

I am now coding in this project. Explain changes clearly, preserve my work and make reviewable commits on a focused branch. If delegation is available, use bounded backend/frontend/QA work packages with explicit file ownership and one integrator; otherwise follow the same sequence yourself. Do not assume previous live agent sessions are available.

After the review-and-fix work, update the backlog and handover evidence and give me the next bounded Sprint 2 task for CAFE-011–014, including its dependencies. Report what works, tests actually run, remaining limitations and changed files. Do not implement all later sprints automatically.
```

For a different next task, replace the first work package while retaining the repository, handoff and evidence instructions. Detailed setup, architecture and scope live in the linked project documents, not in assistant-specific prompts.

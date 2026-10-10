# ADR 0001: Team Roles, Review Protocol, and Repository Governance

## Status
Accepted

## Date
2026-10-10

## Context
Obscure is being built by a solo student founder (CEO) partnered with AI agents filling distinct functional roles:
- ChatGPT (Chief Architect & Technical Strategy Lead)
- Antigravity (Engineering & Implementation Lead)
- Claude (Review & QA Lead)

Because AI agents do not share memory or context across separate sessions, the Founder acts as the central message bus. Without explicit governance, context drift, hallucinated Chromium APIs, and unreviewed breaking changes will rapidly destabilize the project.

## Decisions

1. **Role Separation:**
   - **Founder & CEO:** Decides product direction, scope, and acts as the tie-breaker for conflicting opinions.
   - **Chief Architect (ChatGPT):** Defines macro-architecture, system boundaries, and strategic direction.
   - **Implementation Lead (Antigravity):** Inspects Chromium source, writes code, develops WebUI/C++ shims, creates diffs, and executes builds.
   - **Review & QA Lead (Claude):** Audits architecture, reviews code diffs, evaluates test plans, and checks security/sandboxing implications.

2. **Source of Truth & Dispute Resolution:**
   - The repository's `docs/decisions/` directory is the permanent record. No architectural decision is final until committed here.
   - Any technical dispute concerning security, data persistence, or performance must be decided based on **verifiable evidence** (Chromium source file/line, build log, test script, or benchmark), not speculative statements.

3. **Code Landing Protocol:**
   - Antigravity works on feature branches and does not commit directly to `main`.
   - Every implementation change must produce a clean unified diff for review by Claude.
   - Every change must include an explicit rollback/revert command.
   - No patch is applied to the live Chromium checkout without Claude's QA sign-off or Founder approval.

4. **Chromium Decoupling:**
   - The ~80GB Chromium checkout will NOT be committed to this repository.
   - All custom code will reside in `src/` and be applied onto the Chromium tree as isolated files or unified patches in `patches/`.

## Consequences
- Protects the Chromium baseline from unverified or destructive edits.
- Prevents architectural drift across disparate AI sessions.
- Requires slightly higher upfront discipline (creating diffs and ADRs), which saves dozens of hours in avoided merge conflicts and rebuilds.

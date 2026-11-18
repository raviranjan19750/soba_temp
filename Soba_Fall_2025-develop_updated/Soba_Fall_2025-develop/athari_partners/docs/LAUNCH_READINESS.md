# MyCatalystPlan — Launch Readiness Guide

**Project:** Athari Partners / MyCatalystPlan  
**Date:** June 2026  
**Status:** Product nearly ready for prime time — remaining work is infrastructure, security, QA, and launch operations.

---

## Executive summary

The core product is in strong shape: the 0–5 roadmap, multi-user collaboration, owner approval workflow, and Step 5 execution dashboard are real features, not mockups. What remains is primarily production Firebase setup, securing the OpenAI integration, hosting deployment, structured QA, and legal/operational polish.

---

## Phase 1 — Production backend (do this first)

### 1. Lock down Firebase for real users

- Confirm production project: **catalystplan-bc7d9** (already wired in the repo).
- In Firebase Console:
  - Enable **Email/Password** authentication.
  - Create Firestore in **production mode**.
- Deploy security rules from the repository:

```
firebase login
firebase deploy --only firestore:rules
```

### 2. Add Firebase Storage rules

Logo upload uses Firebase Storage, but storage rules are not yet in the project. Without rules, uploads may fail or be too permissive. Add member-scoped storage rules and deploy before launch.

### 3. Turn off development bypass

In production environment configuration:

- Set `BYPASS_AUTH=false` (or remove it entirely).
- Never ship to real customers with session-cache-only persistence.

### 4. Backfill collaboration data

For companies created before the join-company flow was added:

- Ensure each company has a `collaboratorInviteCode` field.
- Ensure matching `inviteCodes/{code}` documents exist.

New signups handle this automatically; existing tenants may need a one-time backfill.

---

## Phase 2 — Security (blocker for public web launch)

### OpenAI API key exposure

The OpenAI API key currently lives in `.env`, which is bundled as a Flutter asset. On a deployed web app, anyone can extract it from the client bundle.

**Before public launch**, move AI calls to a backend proxy (Firebase Cloud Function or similar):

- Flow: Client → your API → OpenAI
- API key stays server-side only
- Add rate limits per user or per company

Until that is done, treat AI suggestions as **beta-only** or disable them in production web builds.

---

## Phase 3 — Deploy the web app

Firebase Hosting is not yet configured. Typical deployment path:

```
flutter build web --release
firebase init hosting
firebase deploy --only hosting
```

Also plan for:

- Custom domain (e.g. app.mycatalystplan.com)
- SSL (Firebase Hosting provides this)
- Web favicon, page title, and basic PWA metadata
- A simple error or status page if Firebase is unavailable

---

## Phase 4 — End-to-end QA (1–2 days, structured)

Run these flows on **production Firebase** (not bypass mode), using two test accounts: one **owner** and one **collaborator**.

| Flow | Owner | Collaborator |
|------|-------|--------------|
| Sign up and create company | Yes | — |
| Join via invite code | — | Yes |
| Step 0 profile and logo upload | Yes | Yes (draft) |
| Steps 1–5 save and draft ready | Yes | Yes |
| Owner approves each step | Yes | Blocked |
| Step 5 KPI table: metric, quarterly target, quarterly actual | Yes | Yes |
| Roadmap progress updates after approval | Yes | Yes |
| PDF export (if used) | Yes | Yes |

### Known gaps to verify or fix before launch

- **Step 5 draft completion** still keys off 1-Pager vision/mission, not the KPI dashboard — may confuse users who only use the execution table.
- **Owner approval panels** are inline on Steps 1 and 5; Steps 2–4 rely mainly on the roadmap banner.
- **Step 0 profile approval** may still be banner-only, not on the profile page itself.

Decide whether to align completion criteria with the new KPI dashboard before launch, or document current behavior for pilot users.

---

## Phase 5 — Product and legal polish

### Must-have for a real product

- Privacy policy and Terms of use (especially: company data, AI usage, collaborators)
- Support email or help link on landing page and in-app
- Onboarding copy explaining: owner vs collaborator, invite code, approval workflow

### Nice-to-have soon after launch

- Email verification on signup
- Password reset flow tested on web
- “Invite teammate” call-to-action on Company Profile

---

## Phase 6 — Observability and maintenance

- **Crash and error tracking:** Firebase Crashlytics (mobile) or Sentry (web)
- **Analytics:** Firebase Analytics or Plausible — track signup, step completion, approvals
- **Monitoring:** Firestore usage, Storage usage, OpenAI cost alerts
- **Backups:** Firestore export schedule (weekly is a good starting point)

There are almost no automated tests today (only default iOS/macOS runner stubs). For v1, a written QA checklist is acceptable; add integration tests for auth and plan progress before scaling user count.

---

## Phase 7 — Go-live checklist

| Item | Status today |
|------|----------------|
| Core 0–5 planning flow | Largely done |
| Multi-user collaboration and owner approval | Done (polish needed on Steps 0, 2–4) |
| Firestore rules in repository | Done — needs deploy |
| Storage rules | Missing |
| Production hosting | Not configured |
| OpenAI secured for web | Not production-safe |
| BYPASS_AUTH off in production | Verify before launch |
| Privacy policy and Terms | Likely missing |
| README and runbook | Placeholder |
| CI (build and analyze on pull request) | Not set up |

---

## Recommended timeline (next 2–3 weeks)

### Week 1

- Deploy Firestore and Storage rules
- Disable auth bypass in production
- Deploy to a staging URL via Firebase Hosting
- Run full owner and collaborator QA pass

### Week 1–2

- Fix Step 5 completion criteria and approval consistency (if launch UX must be tight)
- Add owner approval panels to remaining steps (optional but recommended)

### Week 2

- Move OpenAI behind Cloud Functions, or disable AI on web for v1
- Add privacy policy, terms, and support contact
- Configure custom domain and error monitoring

### Week 3

- Soft launch with 2–3 pilot companies
- Gather feedback and fix blockers
- Public launch

---

## Suggested next implementation tasks (in the codebase)

1. Firebase Storage rules and Hosting configuration
2. Align Step 5 draft and approval logic with the KPI execution dashboard
3. Owner approval panels on Steps 0–4 (same pattern as Step 1)
4. Cloud Function proxy for OpenAI API calls
5. Production deployment runbook in README.md

---

## How to use this document

- **Copy:** Open this file, select all (Ctrl+A), copy (Ctrl+C), paste into email, Google Docs, or chat.
- **Word:** In Microsoft Word, use File → Open and select this `.md` file, or copy-paste from the file into a new document. Word will preserve headings and tables.
- **PDF:** Open in Word, then File → Save As → PDF.

---

*Generated for MyCatalystPlan / Athari Partners launch planning.*

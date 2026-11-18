# Beta deploy runbook (MyCatalystPlan / catalystplan-bc7d9)

## Prerequisites (Firebase Console)

1. Enable **Authentication → Email/Password**
2. Create **Firestore** (production mode) if missing
3. Create **Storage** if missing (Get started)
4. Confirm project ID is `catalystplan-bc7d9`

## AI suggestions (closed beta)

In `.env`:

```
ENABLE_AI_SUGGESTIONS=false
BYPASS_AUTH=false
```

This hides OpenAI lightbulbs / suggest buttons. Rule-based KPI metric chips still work.
Set `ENABLE_AI_SUGGESTIONS=true` later when AI is behind a secure backend (or for trusted internal testing only).

## One-time: CLI login

```powershell
cd c:\Users\miaja\Downloads\Soba_Fall_2025-develop\Soba_Fall_2025-develop\athari_partners
firebase login
firebase use catalystplan-bc7d9
```

## Deploy security rules

```powershell
firebase deploy --only firestore:rules,storage
```

## Build + deploy web beta

```powershell
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

## Full beta deploy (rules + hosting)

```powershell
flutter build web --release
firebase deploy --only firestore:rules,storage,hosting
```

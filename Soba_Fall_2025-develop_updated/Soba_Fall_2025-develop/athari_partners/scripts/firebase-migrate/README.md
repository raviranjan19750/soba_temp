# Firebase migration: `soba-project-mj` → `catalystplan-bc7d9`

App config in this repo already points at **catalystplan-bc7d9**. Use this script to copy existing Firestore (and optionally Auth) data from the old project.

## 1. Prepare the new Firebase project

In [Firebase Console](https://console.firebase.google.com/) for **catalystplan-bc7d9**:

1. Enable **Authentication** → Email/Password (same as the old app).
2. Create a **Firestore** database (production mode is fine).
3. Deploy security rules from this repo (requires Firebase CLI):

   ```bash
   cd athari_partners
   firebase login
   firebase deploy --only firestore:rules
   ```

## 2. Service account keys

For **both** projects:

1. Project settings → **Service accounts** → **Generate new private key**
2. Save as:
   - `scripts/firebase-migrate/keys/soba-project-mj.json`
   - `scripts/firebase-migrate/keys/catalystplan-bc7d9.json`

Never commit these files (they are gitignored).

## 3. Run Firestore migration

```bash
cd scripts/firebase-migrate
npm install
npm run migrate:dry-run   # preview paths only
npm run migrate             # copy data
```

This copies top-level collections **`users`** and **`companies`**, including all nested subcollections (strategic planning, assessments, year-one plan, etc.).

## 4. Migrate Auth users (optional)

Passwords cannot be copied without an export that includes password hashes.

**Option A – export/import (keeps passwords if hash config matches):**

```bash
firebase auth:export users.json --project soba-project-mj
node migrate.mjs --auth-export users.json
```

**Option B – users create new accounts** on catalystplan-bc7d9 (no script needed).

After migration, existing users sign in with the **same email/password** only if you completed Option A.

## 5. Mobile apps (Android / iOS)

Only a **web** app id was provided. For native builds, register Android/iOS apps in the new Firebase project and run:

```bash
flutterfire configure --project=catalystplan-bc7d9
```

That refreshes `lib/firebase_options.dart` and `android/app/google-services.json` with correct platform app IDs.

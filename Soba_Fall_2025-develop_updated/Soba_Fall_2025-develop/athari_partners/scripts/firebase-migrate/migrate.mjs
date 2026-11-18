/**
 * Copies Firestore data from soba-project-mj → catalystplan-bc7d9.
 *
 * Prerequisites:
 * 1. Service account JSON for BOTH projects (Firebase Console → Project settings → Service accounts).
 * 2. Place keys as:
 *    - scripts/firebase-migrate/keys/soba-project-mj.json
 *    - scripts/firebase-migrate/keys/catalystplan-bc7d9.json
 * 3. npm install in this folder, then: npm run migrate
 *
 * Optional auth: export users from old project, then:
 *   node migrate.mjs --auth-export path/to/users.json
 */

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SOURCE_PROJECT = 'soba-project-mj';
const DEST_PROJECT = 'catalystplan-bc7d9';

const ROOT_COLLECTIONS = ['users', 'companies'];

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const authExportIdx = args.indexOf('--auth-export');
const authExportPath =
  authExportIdx >= 0 ? args[authExportIdx + 1] : null;

function loadServiceAccount(projectId) {
  const path = resolve(__dirname, 'keys', `${projectId}.json`);
  if (!existsSync(path)) {
    throw new Error(
      `Missing service account key: ${path}\n` +
        'Download from Firebase Console → Project settings → Service accounts → Generate new private key.',
    );
  }
  return JSON.parse(readFileSync(path, 'utf8'));
}

function initApp(projectId, credential) {
  return admin.initializeApp(
    {
      credential: admin.credential.cert(credential),
      projectId,
    },
    projectId,
  );
}

async function copyDocumentRecursive(sourceRef, destRef, stats) {
  const snap = await sourceRef.get();
  if (snap.exists) {
    stats.docs++;
    if (!dryRun) {
      await destRef.set(snap.data(), { merge: true });
    }
    console.log(`  ${dryRun ? '[dry-run] ' : ''}doc ${sourceRef.path}`);
  }

  const subcollections = await sourceRef.listCollections();
  for (const subcol of subcollections) {
    const subDocs = await subcol.get();
    for (const doc of subDocs.docs) {
      await copyDocumentRecursive(
        doc.ref,
        destRef.collection(subcol.id).doc(doc.id),
        stats,
      );
    }
  }
}

async function migrateFirestore(sourceDb, destDb) {
  const stats = { docs: 0 };

  for (const collectionId of ROOT_COLLECTIONS) {
    console.log(`\nCollection: ${collectionId}`);
    const topLevel = await sourceDb.collection(collectionId).get();
    for (const doc of topLevel.docs) {
      await copyDocumentRecursive(
        doc.ref,
        destDb.collection(collectionId).doc(doc.id),
        stats,
      );
    }
  }

  return stats;
}

async function migrateAuth(sourceAuth, destAuth) {
  if (!authExportPath) {
    console.log(
      '\nAuth: skipped (pass --auth-export <users.json> from firebase auth:export).',
    );
    console.log(
      'Users must sign up again on the new project, or run auth export/import with password hashes.',
    );
    return { imported: 0 };
  }

  if (!existsSync(authExportPath)) {
    throw new Error(`Auth export file not found: ${authExportPath}`);
  }

  const payload = JSON.parse(readFileSync(authExportPath, 'utf8'));
  const users = payload.users ?? [];
  if (users.length === 0) {
    console.log('\nAuth: export file has no users.');
    return { imported: 0 };
  }

  if (dryRun) {
    console.log(`\nAuth: [dry-run] would import ${users.length} user(s).`);
    return { imported: users.length };
  }

  const result = await destAuth.importUsers(users, {
    hash: payload.hash ?? undefined,
  });
  console.log(`\nAuth: imported ${users.length - result.failureCount} user(s).`);
  if (result.errors?.length) {
    console.warn('Auth import errors:', result.errors);
  }
  return { imported: users.length - (result.failureCount ?? 0) };
}

async function main() {
  console.log(
    `Firebase migration: ${SOURCE_PROJECT} → ${DEST_PROJECT}${dryRun ? ' (dry-run)' : ''}`,
  );

  const sourceCred = loadServiceAccount(SOURCE_PROJECT);
  const destCred = loadServiceAccount(DEST_PROJECT);

  initApp(SOURCE_PROJECT, sourceCred);
  initApp(DEST_PROJECT, destCred);

  const sourceDb = admin.firestore(admin.app(SOURCE_PROJECT));
  const destDb = admin.firestore(admin.app(DEST_PROJECT));
  const sourceAuth = admin.auth(admin.app(SOURCE_PROJECT));
  const destAuth = admin.auth(admin.app(DEST_PROJECT));

  const firestoreStats = await migrateFirestore(sourceDb, destDb);
  const authStats = await migrateAuth(sourceAuth, destAuth);

  console.log('\n--- Summary ---');
  console.log(`Firestore documents ${dryRun ? 'found' : 'copied'}: ${firestoreStats.docs}`);
  console.log(`Auth users ${dryRun ? 'to import' : 'imported'}: ${authStats.imported}`);
  if (!dryRun) {
    console.log(
      '\nNext: deploy Firestore rules to the new project:\n' +
        '  firebase deploy --only firestore:rules\n' +
        '(from athari_partners with .firebaserc pointing at catalystplan-bc7d9)',
    );
  }
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});

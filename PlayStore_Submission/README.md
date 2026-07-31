# PlayStore_Submission/

This folder contains all documentation and reference files needed to submit **Fitora v1.0** to the Google Play Store.

---

## Folder Structure

```
PlayStore_Submission/
│
├── README.md                   ← This file. Explains folder structure and usage.
│
├── APP_INFORMATION.md          ← Core app metadata (name, package, version, contact).
│
├── STORE_LISTING.md            ← Play Store listing copy (title, descriptions, what's new).
│
├── PLAY_CONSOLE_CHECKLIST.md   ← Step-by-step guide from creating the app to Internal Testing.
│
├── DATA_SAFETY_CHECKLIST.md    ← Play Console Data Safety section — all questions with blanks
│                                  to be filled in before submission.
│
└── PERMISSIONS.md              ← Every Android permission declared in AndroidManifest.xml
                                   with explanations for Play Store review justification.
```

---

## How to Use

1. **Start with `APP_INFORMATION.md`** — confirm all identifiers are correct.
2. **Fill in `STORE_LISTING.md`** — write your final title, descriptions, and release notes.
3. **Answer `DATA_SAFETY_CHECKLIST.md`** — every question must be answered before submission.
4. **Follow `PLAY_CONSOLE_CHECKLIST.md`** — step by step from Play Console setup to Internal Testing.
5. **Reference `PERMISSIONS.md`** — use the justifications if Google Play asks why each permission is needed.

---

## Build Artifacts Location

After running `flutter build appbundle --release`:

| Artifact | Path |
|----------|------|
| AAB (Play Store) | `build/app/outputs/bundle/release/app-release.aab` |
| APK (sideload/test) | `build/app/outputs/flutter-apk/app-release.apk` |

---

## Important Pre-Submission Steps

Before uploading to Play Console:

- [ ] Repository is committed and pushed (see collaborator readiness audit)
- [ ] Package name `com.subhash.fitora` is registered in Firebase Console
- [ ] Fresh `google-services.json` downloaded after Firebase registration
- [ ] Release keystore created and `key.properties` configured
- [ ] `flutter build appbundle --release` run with production signing
- [ ] AAB tested on a physical device via Internal Testing before promoting

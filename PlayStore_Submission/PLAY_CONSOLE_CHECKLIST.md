# Play Console Submission Checklist — Fitora v1.0

> Work through this checklist in order.
> Every item must be completed before promoting to Production.

---

## Phase 1 — Pre-Console Preparation

### 1.1 Build & Signing
- [ ] Release keystore created (`fitora-release.jks`)
- [ ] `android/key.properties` created with keystore credentials
- [ ] `key.properties` added to `.gitignore`
- [ ] `flutter build appbundle --release` executed successfully with production signing
- [ ] AAB located at `build/app/outputs/bundle/release/app-release.aab`
- [ ] AAB verified with `bundletool` or installed via Internal Testing track

### 1.2 Firebase
- [ ] Android app re-registered in Firebase Console with package `com.subhash.fitora`
- [ ] SHA-1 fingerprint of **upload key** added to Firebase project
- [ ] Fresh `google-services.json` downloaded and placed at `android/app/google-services.json`
- [ ] Google Sign-In tested on a physical device with the new package registration

### 1.3 Code Quality Gate
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — all tests passing
- [ ] No placeholder text visible in the app
- [ ] No debug panels visible in release build

### 1.4 Privacy Policy
- [ ] Privacy Policy written and published at a public URL
- [ ] URL reachable from a browser (not behind a login)

---

## Phase 2 — Google Play Console Setup

### 2.1 Create the App
- [ ] Log in to [play.google.com/console](https://play.google.com/console)
- [ ] Click **"Create app"**
- [ ] App name: `Fitora – AI Fitness & Wellness` (or chosen title)
- [ ] Default language: `English (United States)`
- [ ] App or Game: `App`
- [ ] Free or paid: `Free`
- [ ] Accept Developer Programme Policies
- [ ] Accept US export laws declaration
- [ ] Click **"Create app"**

### 2.2 App Content — Policy Declarations

#### Ads
- [ ] Navigate to **Policy → App content → Ads**
- [ ] Declare whether app contains ads: `[ ] Yes  [ ] No`
- [ ] Save

#### App Access
- [ ] Navigate to **Policy → App content → App access**
- [ ] If login is required: add test credentials for reviewer
- [ ] Save

#### Content Rating
- [ ] Navigate to **Policy → App content → Content rating**
- [ ] Click **"Start questionnaire"**
- [ ] Select category: **Utility** or **Health & Fitness**
- [ ] Answer all questions honestly
- [ ] Apply rating
- [ ] Save

#### Target Audience
- [ ] Navigate to **Policy → App content → Target audience**
- [ ] Select target age group (18+ recommended for health data)
- [ ] Save

#### News App
- [ ] Navigate to **Policy → App content → News apps**
- [ ] Declare: `This app is not a news app`
- [ ] Save

#### COVID-19 Contact Tracing (if applicable)
- [ ] Navigate to **Policy → App content → COVID-19 contact tracing**
- [ ] Declare: `This app is not a COVID-19 contact tracing or status app`
- [ ] Save

#### Data Safety
- [ ] Navigate to **Policy → Data safety**
- [ ] Complete the full questionnaire (see `DATA_SAFETY_CHECKLIST.md`)
- [ ] Preview the Data Safety section before saving
- [ ] Save and confirm

#### Privacy Policy
- [ ] Navigate to **Policy → App content → Privacy Policy**
- [ ] Enter Privacy Policy URL
- [ ] Save

---

## Phase 3 — Store Listing

### 3.1 Main Store Listing
- [ ] Navigate to **Grow → Store presence → Main store listing**
- [ ] App name: filled in (max 50 chars)
- [ ] Short description: filled in (max 80 chars)
- [ ] Full description: filled in (max 4,000 chars)
- [ ] Save

### 3.2 Graphics
- [ ] Feature graphic uploaded (1024 × 500 px, JPG or PNG, no alpha)
- [ ] At least 2 phone screenshots uploaded (min 320px, max 3840px on any side)
- [ ] App icon confirmed (auto-generated from AAB — must be 512 × 512 px, max 1MB)
- [ ] Save

### 3.3 Categorization
- [ ] Navigate to **Grow → Store presence → Main store listing → App category**
- [ ] Application type: `App`
- [ ] Category: `Health & Fitness`
- [ ] Tags: _(add relevant tags e.g. fitness, step counter, wellness)_
- [ ] Save

### 3.4 Contact Details
- [ ] Email address: filled in
- [ ] Website: filled in (if available)
- [ ] Phone: filled in (optional)
- [ ] Save

---

## Phase 4 — Release Setup

### 4.1 Internal Testing Track
- [ ] Navigate to **Testing → Internal testing**
- [ ] Click **"Create new release"**
- [ ] Upload AAB: `app-release.aab`
- [ ] Confirm signing — select **"Use Google-managed key"** (Play App Signing)
  - _(or upload your own signing key if not using Play App Signing)_
- [ ] Enter release name: `Fitora v1.0.0 (RC1)`
- [ ] Enter release notes (from `STORE_LISTING.md → What's New`)
- [ ] Click **"Save"** then **"Review release"**
- [ ] Click **"Start rollout to internal testing"**

### 4.2 Add Testers
- [ ] Navigate to **Testing → Internal testing → Testers**
- [ ] Create or select a tester list
- [ ] Add tester email addresses
- [ ] Save
- [ ] Share the opt-in link with testers

### 4.3 Internal Testing Validation
- [ ] All testers can install via opt-in link
- [ ] App installs successfully on Android 8+ devices
- [ ] Onboarding permission flow works
- [ ] Step tracking works
- [ ] Health Connect syncs (on supported devices)
- [ ] Hydration reminders fire on schedule
- [ ] No crashes in the first 10 minutes of use
- [ ] Google Sign-In works
- [ ] Settings save and persist after restart

---

## Phase 5 — Promote to Production (After QA)

- [ ] All Internal Testing issues resolved
- [ ] Pre-launch report reviewed in Play Console
- [ ] Navigate to **Testing → Internal testing → Promote release**
- [ ] Select **"Production"** track
- [ ] Set rollout percentage: `20%` → monitor → `100%`
- [ ] Confirm all policy sections are complete (green checkmarks)
- [ ] Click **"Start rollout to Production"**

---

## Final Checklist Before Hitting "Publish"

- [ ] Store listing looks correct in preview
- [ ] Data Safety section is complete and accurate
- [ ] Privacy Policy URL is live and accessible
- [ ] Content rating applied
- [ ] Release notes match the version
- [ ] Contact email is monitored

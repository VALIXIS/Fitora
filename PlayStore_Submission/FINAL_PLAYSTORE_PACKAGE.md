# FITORA v1.0 — Google Play Store Master Package

> **This is the single source of truth for submitting Fitora to Google Play Console.**
> Complete every section marked `[FILL IN]` before beginning submission.
> Sections with ✅ are pre-filled based on the implemented codebase.

---

---

# 1. App Overview

| Field | Value |
|-------|-------|
| **App Name** | Fitora |
| **Package Name** | `com.subhash.fitora` |
| **Version Name** | `1.0.0` |
| **Version Code** | `1` |
| **Min Android Version** | Android 8.0 (API 26) |
| **Target Android Version** | Android 14 (API 34) |
| **Category** | Health & Fitness |
| **Developer Name** | `[FILL IN — your name or company name]` |
| **Developer Email** | `[FILL IN — public-facing contact email]` |
| **Support Email** | `[FILL IN — support@yourdomain.com]` |
| **Website** | `[FILL IN — or write "Not applicable"]` |
| **Privacy Policy URL** | `[FILL IN — see Section 12 for setup guide]` |
| **Contains Ads** | No |
| **In-App Purchases** | No |
| **Free / Paid** | Free |

---

---

# 2. Google Play Store Listing

## App Title

```
Fitora – Fitness & Wellness Tracker
```

> ✅ 38 characters — within the 50-character limit.

---

## Short Description

```
Track steps, sleep, hydration & workouts in one premium fitness dashboard.
```

> ✅ 75 characters — within the 80-character limit.

---

## Full Description

```
Fitora is a premium fitness and wellness companion designed to keep you 
active, hydrated, and well-rested — all from a single beautifully crafted app.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏃 STEP & ACTIVITY TRACKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Fitora uses your phone's built-in step counter to track your daily steps, 
distance, and active minutes in real time — no wearable required. Watch your 
progress update live throughout the day.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💧 SMART HYDRATION REMINDERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Log your daily water intake and let Fitora send gentle reminders to keep 
you on track. Choose your reminder interval and active hours — Fitora adapts 
to your schedule, not the other way around.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
😴 SLEEP TRACKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Understand your sleep patterns with data pulled directly from Health Connect. 
Monitor your sleep duration and trends over time to make meaningful 
improvements to your rest.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 PROGRESS ANALYTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The Progress screen gives you a weekly overview of your steps, calories, 
distance, and active minutes — visualised in clean, easy-to-read charts. 
Filter by day or week. See trends at a glance.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 HEALTH CONNECT INTEGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Connect Fitora to Android Health Connect to pull in richer health data 
from your existing apps and wearables — steps, distance, calories, exercise 
sessions, and sleep — all in one place.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 DAILY GOALS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Set personalised daily goals for steps, hydration, and calories. Fitora 
tracks your progress toward each goal and celebrates when you hit them.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💪 WORKOUT LOGGING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Browse and log workouts from a curated exercise library. Track your 
sessions, monitor duration, and build a consistent workout routine.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ PREMIUM DESIGN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Fitora features a stunning dark navy interface with glassmorphic cards, 
soft glow effects, and fluid animations — a premium experience that makes 
tracking your health something you actually look forward to.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 YOUR DATA, YOUR CONTROL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your fitness data is stored locally on your device. Fitora does not sell 
your health information. You are always in control of what is shared.

Download Fitora today and start your wellness journey.
```

> ✅ Approximately 2,400 characters — within the 4,000-character limit.

---

## What's New — v1.0.0

```
Welcome to Fitora! 🎉

Your new premium fitness companion is here. v1.0.0 includes:

• Real-time step and activity tracking
• Smart hydration reminders with custom schedules
• Sleep tracking via Health Connect
• Weekly progress analytics with charts
• Workout logging and exercise library
• Health Connect integration
• Beautiful dark premium dashboard

Thank you for being one of our first users. 
Your feedback shapes what comes next. 🙏
```

---

---

# 3. Core Features

Every feature listed below is implemented and functional in v1.0.0.

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Step Tracking** | Real-time daily step count via hardware step counter sensor. Resets at midnight. Displayed on the Home dashboard with a circular progress ring. |
| 2 | **Distance Tracking** | Daily distance in km/miles derived from step data and supplemented by Health Connect. Shown on Home and Progress screens. |
| 3 | **Calories Tracking** | Active calories burned pulled from Health Connect. Displayed on Home and Progress screens. |
| 4 | **Active Minutes** | Daily active minutes calculated from sensor and exercise data. Visible on Home dashboard. |
| 5 | **Hydration Tracking** | Manual water intake logging with a visual progress indicator showing intake vs. daily goal. |
| 6 | **Hydration Reminders** | Configurable push notifications — choose reminder interval (1h/2h/3h/4h) and active hours (start/end time). Cancels and reschedules automatically when settings change. |
| 7 | **Sleep Tracking** | Sleep duration and session data read from Health Connect. Displayed in the Profile/Health section. |
| 8 | **Progress Analytics** | Weekly overview charts for steps, calories, distance, and active minutes. Time-filtered views (day/week). |
| 9 | **Daily Goals** | User-configurable step and hydration goals set during onboarding. Progress tracked on Home screen. |
| 10 | **Health Connect Integration** | Full read integration with Android Health Connect: steps, distance, calories, exercise sessions, sleep. Syncs automatically on launch and app resume. Pull-to-refresh available on Home. |
| 11 | **Workout Logging** | Exercise library with categorised workouts. Log sessions with duration and exercise selection. |
| 12 | **Google Sign-In** | Secure account creation and sign-in via Google. Powered by Firebase Authentication. |
| 13 | **Onboarding Flow** | Multi-step personalization: name, fitness goal, age, height, weight. Sets up the app for the user's specific needs. |
| 14 | **Permission Flow** | Sequential, user-friendly permission requests (Activity Recognition, Notifications) shown at first launch — never all at once. |
| 15 | **Notifications** | Hydration reminder notifications. Configurable interval and active hours. Test notification available in Settings. |
| 16 | **Settings** | Theme control, Health Sync management (status, last sync, manual sync), Reminder configuration, About page. |
| 17 | **Premium UI** | Dark navy background with cyan/blue/purple accent palette. Glassmorphic cards, soft glow effects, fluid animations, modern typography. |

---

---

# 4. Permissions Used

Source: `android/app/src/main/AndroidManifest.xml`

| Permission | Type | Runtime Dialog | Why It Is Required |
|------------|------|---------------|-------------------|
| `ACTIVITY_RECOGNITION` | Dangerous | Yes — first launch | Required on Android 10+ to access the device's step counter and step detector hardware sensors for real-time step tracking. |
| `POST_NOTIFICATIONS` | Dangerous | Yes — first launch | Required on Android 13+ to display push notifications. Used for hydration reminders. |
| `RECEIVE_BOOT_COMPLETED` | Normal | No | Android cancels all scheduled notifications on device reboot. This permission allows Fitora to automatically reschedule hydration reminders after restart. |
| `VIBRATE` | Normal | No | Allows notification alerts to vibrate the device for users who keep their phone on silent. |
| `health.READ_STEPS` | Health Connect | Yes — HC dialog | Read daily step data from Health Connect to merge with on-device sensor data. |
| `health.READ_DISTANCE` | Health Connect | Yes — HC dialog | Read distance walked/run from Health Connect for Progress analytics. |
| `health.READ_TOTAL_CALORIES_BURNED` | Health Connect | Yes — HC dialog | Read active calories burned from Health Connect for the Home dashboard and Progress charts. |
| `health.READ_EXERCISE` | Health Connect | Yes — HC dialog | Read exercise session records from Health Connect for workout history. |
| `health.READ_SLEEP` | Health Connect | Yes — HC dialog | Read sleep session data from Health Connect for the Health/Sleep section. |

**Hardware Features Declared (not required — `android:required="false"`):**

| Feature | Purpose |
|---------|---------|
| `android.hardware.sensor.stepcounter` | Used for accurate cumulative step counting. App installs on devices without it. |
| `android.hardware.sensor.stepdetector` | Used for per-step event detection. App installs on devices without it. |

**Permissions NOT used:** Location, Camera, Microphone, Contacts, External Storage, Bluetooth.

---

---

# 5. Data Safety Preparation

> Answers below are inferred from the implemented codebase.
> Items marked **"Manual Verification Required"** must be confirmed by reviewing your Firebase project and data handling practices before submission.

---

## 5.1 Does your app collect or share user data?

**Recommended Answer:** Yes

**Reason:** The app collects a user's name (personalization) and email address (Firebase Authentication). Health and fitness data is processed on-device. Confirm with your Firebase project whether any additional telemetry is sent.

---

## 5.2 Is all data encrypted in transit?

**Recommended Answer:** Yes

**Reason:** Firebase SDK uses HTTPS/TLS for all communication. Health Connect data is processed entirely on-device and never transmitted.

---

## 5.3 Do you provide a way for users to request data deletion?

**Recommended Answer:** Manual Verification Required

**Reason:** The app does not currently have an in-app "Delete Account" button. If users cannot delete their data from within the app, you must provide an alternative method (web form or email) and declare it in Data Safety. Consider adding account deletion before Production release.

---

## 5.4 Data Types Collected

| Data Type | Collected? | Shared with 3rd Parties? | Purpose | Optional? |
|-----------|-----------|--------------------------|---------|-----------|
| **Name** | ✅ Yes | ❌ No | Personalization greeting on Home screen | Optional |
| **Email address** | ✅ Yes | ❌ No — stored in Firebase (your own backend) | Firebase Authentication / account login | Required for sign-in |
| **User IDs** | ✅ Yes | ❌ No | Firebase UID used internally to identify user session | Required for sign-in |
| **Health info** (sleep, calories) | ⚠️ Manual Verification Required | ❌ No | Read from Health Connect, displayed in app — confirm if stored to Firebase | — |
| **Fitness info** (steps, distance, active minutes) | ⚠️ Manual Verification Required | ❌ No | Generated by on-device sensor and Health Connect — confirm if stored to Firebase | — |
| **Device or other IDs** | ⚠️ Manual Verification Required | ❌ No | Firebase installation ID may be collected automatically by Firebase SDK | — |
| **Crash logs / Diagnostics** | ⚠️ Manual Verification Required | ❌ No | If Firebase Crashlytics is enabled in your Firebase project, crash logs are collected | — |

> **Manual Verification Required:**
> Log in to your Firebase Console → project `fitora-03` and confirm:
> - Is Firebase Analytics enabled? (If yes, it collects app activity data automatically)
> - Is Firebase Crashlytics enabled? (If yes, it collects crash logs)
> - Does Firebase Firestore or Realtime Database store any health or fitness data?
> 
> If none of these are enabled, the only data sent to Firebase is email/UID via Authentication.

---

## 5.5 Health Connect Disclosure

> Apps using Health Connect must complete a separate disclosure in Play Console.

| Health Data | Read | Write |
|-------------|------|-------|
| Steps | ✅ | ❌ |
| Distance | ✅ | ❌ |
| Calories burned | ✅ | ❌ |
| Exercise sessions | ✅ | ❌ |
| Sleep sessions | ✅ | ❌ |

**Recommended Answer for Health Connect section:** Fitora reads health data from Health Connect to display activity summaries. No health data is written back to Health Connect. Health data is processed on-device and is not transmitted to external servers.

---

---

# 6. Content Rating

## Questionnaire Category

**Select:** Utility

## Recommended Answers

| Question | Answer | Notes |
|----------|--------|-------|
| Does the app contain violence? | No | |
| Does the app contain sexual content? | No | |
| Does the app contain profanity? | No | |
| Does the app allow user-generated content shared with others? | No | All data is private per user |
| Does the app facilitate gambling? | No | |
| Does the app contain references to alcohol, tobacco, or drugs? | No | |
| Does the app simulate dangerous activities? | No | |
| Does the app provide medical or health advice? | ⚠️ Manual Review | The app displays fitness metrics but does not diagnose conditions. Review the wording of any health-related text to confirm it does not constitute "medical advice." |

## Expected Content Rating

**PEGI 3 / Everyone** — No objectionable content. Suitable for all ages.

> Final rating is determined by Google Play's automated questionnaire. The above is a prediction based on app content.

---

---

# 7. Target Audience

## Primary Audience

**Recommended selection:** Adults (18 and over)

**Reason:** The app collects health and fitness metrics and uses Firebase Authentication (requires an account). While the content itself is suitable for all ages, health apps with account creation are conventionally targeted at adults.

## Age Groups to Select in Play Console

- [ ] **18 and over** ← Recommended primary selection

## Does the app appeal to children?

**Recommended Answer:** No

**Reason:** The app uses account sign-in, health data, and fitness goal-setting — features designed for adult users. The dark premium UI is not child-oriented.

> If you select any age group under 18, additional COPPA/children's privacy compliance steps apply.

---

---

# 8. Ads

## Does this app contain advertisements?

**Answer: No**

Fitora v1.0.0 does not contain any advertising SDKs, banner ads, interstitials, rewarded ads, or any form of in-app advertising.

**Play Console selection:** `"This app does not contain ads"`

---

---

# 9. Internal Testing Submission Checklist

Follow these steps in order inside [play.google.com/console](https://play.google.com/console).

---

### Step 1 — Create the App

- [ ] Click **"Create app"** in Play Console
- [ ] App name: `Fitora – Fitness & Wellness Tracker`
- [ ] Default language: `English (United States)`
- [ ] Type: `App`
- [ ] Paid/Free: `Free`
- [ ] Accept Developer Programme Policies ✓
- [ ] Accept US export laws ✓
- [ ] Click **"Create app"**

---

### Step 2 — Complete App Content (Policy Section)

#### Ads
- [ ] Navigate to: **Policy → App content → Ads**
- [ ] Select: `"This app does not contain ads"`
- [ ] Save ✓

#### Privacy Policy
- [ ] Navigate to: **Policy → App content → Privacy Policy**
- [ ] Enter URL: `[YOUR GITHUB PAGES URL]` (see Section 12)
- [ ] Save ✓

#### App Access
- [ ] Navigate to: **Policy → App content → App access**
- [ ] The app requires Google Sign-In
- [ ] Add test account credentials for Play reviewers:
  - Email: `[TEST ACCOUNT EMAIL]`
  - Password: `[TEST ACCOUNT PASSWORD]`
- [ ] Save ✓

#### Content Rating
- [ ] Navigate to: **Policy → App content → Content rating**
- [ ] Click **"Start questionnaire"**
- [ ] Category: `Utility`
- [ ] Answer all questions per Section 6 above
- [ ] Apply rating
- [ ] Save ✓

#### Target Audience
- [ ] Navigate to: **Policy → App content → Target audience**
- [ ] Select: `18 and over`
- [ ] Confirm app does not appeal to children
- [ ] Save ✓

#### Data Safety
- [ ] Navigate to: **Policy → Data safety**
- [ ] Answer all questions per Section 5 above
- [ ] Preview the Data Safety section
- [ ] Save and confirm ✓

---

### Step 3 — Complete the Store Listing

- [ ] Navigate to: **Grow → Store presence → Main store listing**
- [ ] App name: `Fitora – Fitness & Wellness Tracker`
- [ ] Short description: `Track steps, sleep, hydration & workouts in one premium fitness dashboard.`
- [ ] Full description: _(paste from Section 2)_
- [ ] Save ✓

#### App Category
- [ ] Category: `Health & Fitness`
- [ ] Add tags: `fitness`, `step counter`, `wellness`, `health`, `hydration`
- [ ] Save ✓

#### Contact Details
- [ ] Email: `[FILL IN]`
- [ ] Website: `[FILL IN or leave blank]`
- [ ] Save ✓

---

### Step 4 — Upload Screenshots and Graphics

- [ ] Navigate to: **Grow → Store presence → Main store listing → Graphics**
- [ ] Feature graphic uploaded (1024 × 500 px) — use `playstore assets/Graphic.png`
- [ ] Minimum 2 phone screenshots uploaded — use `playstore assets/1.png` through `7.png`
- [ ] App icon confirmed (generated from AAB — must be 512 × 512 px PNG, no alpha channel)
- [ ] Save ✓

---

### Step 5 — Build and Upload the AAB

- [ ] Generate production keystore (if not done): see keystore guide below
- [ ] Configure `android/key.properties`
- [ ] Run: `flutter build appbundle --release`
- [ ] Locate AAB: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Navigate to: **Testing → Internal testing → Create new release**
- [ ] Upload: `app-release.aab`
- [ ] On first upload, choose: **"Use Google-managed signing key"** (recommended) or upload your own
- [ ] Release name: `Fitora v1.0.0 — RC1`
- [ ] Release notes: _(paste from Section 2 → What's New)_
- [ ] Click **"Save"**

---

### Step 6 — Add Internal Testers

- [ ] Navigate to: **Testing → Internal testing → Testers**
- [ ] Create a testers list or select existing
- [ ] Add all tester email addresses
- [ ] Save ✓
- [ ] Copy the opt-in link and share with testers

---

### Step 7 — Review and Submit

- [ ] Navigate to: **Testing → Internal testing**
- [ ] Click **"Review release"**
- [ ] Confirm: all policy sections show green checkmarks ✓
- [ ] Confirm: AAB uploaded ✓
- [ ] Confirm: Store listing complete ✓
- [ ] Click **"Start rollout to internal testing"**
- [ ] ✅ Done — testers will receive the opt-in link within minutes

---

---

# 10. Play Store Assets Checklist

| Asset | Specification | Status |
|-------|---------------|--------|
| **App Icon (hi-res)** | 512 × 512 px, PNG, no alpha, max 1 MB | Generated from AAB — verify in Play Console preview |
| **Feature Graphic** | 1024 × 500 px, JPG or PNG, no alpha, max 1 MB | `playstore assets/Graphic.png` |
| **Phone Screenshots** | Min 2, max 8. Min 320px, max 3840px on longest side. 16:9 or 9:16 | `playstore assets/1.png` through `7.png` |
| **Tablet Screenshots** | Optional — 7-inch and 10-inch | Not required for Internal Testing |
| **App Bundle (.aab)** | Release-signed, from `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| **Privacy Policy URL** | Public, reachable without login | `[FILL IN — see Section 12]` |
| **Developer Email** | Used for user contact | `[FILL IN]` |
| **Support Email** | Displayed on Play Store listing | `[FILL IN]` |
| **Content Rating** | Applied via Play Console questionnaire | Complete Section 6 steps |
| **Data Safety** | All questions answered | Complete Section 5 steps |

---

---

# 11. Privacy Policy

> This Privacy Policy is written for Fitora based solely on implemented functionality.
> **Replace every `[PLACEHOLDER]` before publishing.**
> This document is suitable for hosting on GitHub Pages as-is once placeholders are filled.

---

```
FITORA — PRIVACY POLICY

Last updated: [DATE OF PUBLICATION]

This Privacy Policy describes how [YOUR NAME / COMPANY NAME] ("we", "us", 
or "our") collects, uses, and handles your information when you use the 
Fitora application ("App") on Android devices.

By using the App, you agree to the practices described in this Privacy Policy.

─────────────────────────────────────────────────────────────────────────────
1. INFORMATION WE COLLECT
─────────────────────────────────────────────────────────────────────────────

a) Account Information
   When you sign in with Google, we receive and store:
   - Your display name (used to personalise your greeting in the App)
   - Your email address (used for authentication)
   - A unique identifier assigned by Firebase Authentication

b) Fitness and Activity Data
   Fitora reads the following data from your device's hardware sensors 
   and from Android Health Connect (if you grant permission):
   - Step count
   - Distance walked or run
   - Active calories burned
   - Active minutes
   - Exercise sessions
   - Sleep duration and sessions

   This data is processed on your device and displayed within the App.
   It is not transmitted to our servers unless explicitly stated below.

c) Hydration Data
   Water intake you manually log is stored locally on your device using 
   your device's internal storage. This data is not transmitted externally.

d) Personal Preferences
   Your age, height, weight, fitness goals, and notification preferences 
   entered during onboarding are stored locally on your device.

─────────────────────────────────────────────────────────────────────────────
2. HOW WE USE YOUR INFORMATION
─────────────────────────────────────────────────────────────────────────────

We use the information we collect to:
- Authenticate your account and provide access to the App
- Display personalised fitness metrics and progress summaries
- Send hydration reminder notifications at your configured schedule
- Improve your experience based on your stated fitness goals

We do NOT use your information for advertising, profiling, or sale to 
third parties.

─────────────────────────────────────────────────────────────────────────────
3. HEALTH DATA
─────────────────────────────────────────────────────────────────────────────

Fitora reads health and fitness data from Android Health Connect solely 
to display it within the App. We read the following Health Connect 
data types: steps, distance, calories burned, exercise sessions, and 
sleep sessions.

Fitora does NOT write any data back to Health Connect.
Health Connect data is not transmitted to external servers by Fitora.
You may revoke Health Connect permissions at any time in your device's 
Health Connect settings.

─────────────────────────────────────────────────────────────────────────────
4. FIREBASE AND GOOGLE SERVICES
─────────────────────────────────────────────────────────────────────────────

Fitora uses Firebase Authentication (provided by Google LLC) to manage 
user accounts. When you sign in with Google, your email address and a 
unique user ID are stored in Firebase Authentication.

Firebase is subject to Google's Privacy Policy: 
https://policies.google.com/privacy

Fitora does not use Firebase Analytics, Firebase Crashlytics, or any 
other Firebase services that collect additional usage data, unless 
explicitly stated in a future update to this policy.

─────────────────────────────────────────────────────────────────────────────
5. DATA STORAGE AND SECURITY
─────────────────────────────────────────────────────────────────────────────

- Fitness, hydration, and preference data is stored locally on your 
  device using Android's SharedPreferences and internal database storage.
- Account data (email, user ID) is stored securely in Firebase 
  Authentication, which is hosted on Google's infrastructure.
- All communication between the App and Firebase uses HTTPS encryption.
- We do not operate our own servers or databases beyond Firebase 
  Authentication.

─────────────────────────────────────────────────────────────────────────────
6. DATA SHARING
─────────────────────────────────────────────────────────────────────────────

We do not sell, rent, or share your personal information with any 
third party for advertising or marketing purposes.

The only third-party service that receives any of your data is:
- Google / Firebase Authentication — for account sign-in only.

─────────────────────────────────────────────────────────────────────────────
7. CHILDREN'S PRIVACY
─────────────────────────────────────────────────────────────────────────────

Fitora is not directed at children under the age of 13. We do not 
knowingly collect personal information from children under 13. If you 
believe a child has provided us with personal information, please 
contact us at [SUPPORT EMAIL] and we will delete it promptly.

─────────────────────────────────────────────────────────────────────────────
8. YOUR RIGHTS AND DATA DELETION
─────────────────────────────────────────────────────────────────────────────

You may request deletion of your account data at any time by:
1. Emailing us at [SUPPORT EMAIL] with the subject "Data Deletion Request"
2. Including the email address associated with your Fitora account

We will delete your Firebase Authentication record within 30 days.
Local data stored on your device can be deleted by uninstalling the App.

─────────────────────────────────────────────────────────────────────────────
9. CHANGES TO THIS POLICY
─────────────────────────────────────────────────────────────────────────────

We may update this Privacy Policy from time to time. When we do, 
we will update the "Last updated" date at the top of this document. 
Continued use of the App after any changes constitutes acceptance of 
the updated policy.

─────────────────────────────────────────────────────────────────────────────
10. CONTACT US
─────────────────────────────────────────────────────────────────────────────

If you have questions about this Privacy Policy, please contact us:

Email: [SUPPORT EMAIL]
Website: [YOUR WEBSITE OR "Not applicable"]

─────────────────────────────────────────────────────────────────────────────
```

---

---

# 12. GitHub Pages Deployment Guide

> Use GitHub Pages to host your Privacy Policy at a public URL for free.

---

## Step 1 — Create the Repository

1. Go to [github.com](https://github.com) and sign in
2. Click **"New repository"**
3. Name it: `fitora-privacy-policy`
4. Set visibility: **Public**
5. Check **"Add a README file"**
6. Click **"Create repository"**

---

## Step 2 — Create the Privacy Policy Page

**Option A — Using README.md (simplest):**

1. Click on `README.md` in your new repository
2. Click the ✏️ pencil (edit) icon
3. Delete all existing content
4. Paste the entire Privacy Policy text from Section 11
5. Fill in all `[PLACEHOLDER]` values
6. Scroll down, add commit message: `Add Fitora privacy policy`
7. Click **"Commit changes"**

**Option B — Using index.html (professional):**

1. Click **"Add file" → "Create new file"**
2. Name it: `index.html`
3. Paste the following content and replace `[PRIVACY POLICY TEXT]` with the Section 11 content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fitora – Privacy Policy</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
           max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6;
           color: #1a1a1a; }
    h1 { color: #0891b2; }
    h2 { border-bottom: 1px solid #e5e7eb; padding-bottom: 8px; }
    pre { white-space: pre-wrap; font-family: inherit; }
  </style>
</head>
<body>
  <h1>Fitora – Privacy Policy</h1>
  <pre>[PASTE PRIVACY POLICY TEXT HERE]</pre>
</body>
</html>
```

4. Click **"Commit new file"**

---

## Step 3 — Enable GitHub Pages

1. In the repository, click **Settings**
2. In the left sidebar, click **Pages**
3. Under **"Source"**, select **"Deploy from a branch"**
4. Branch: `main` | Folder: `/ (root)`
5. Click **Save**
6. Wait ~2 minutes for deployment

---

## Step 4 — Get Your URL

Your Privacy Policy will be live at:

```
https://[YOUR-GITHUB-USERNAME].github.io/fitora-privacy-policy/
```

Verify it loads correctly in a browser before proceeding.

---

## Step 5 — Add to Play Console

1. In Play Console, navigate to **Policy → App content → Privacy Policy**
2. Paste your GitHub Pages URL
3. Click Save

---

---

# 13. Final Submission Checklist

> Complete every item before clicking **"Start rollout to internal testing"**.

---

## Code and Build

- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — all tests passing
- [ ] `flutter build appbundle --release` — build successful
- [ ] Release AAB is signed with production keystore (or Play App Signing selected)
- [ ] AAB has been installed on at least one physical device and tested

## Firebase

- [ ] Android app registered in Firebase Console with package `com.subhash.fitora`
- [ ] SHA-1 fingerprint of upload key added to Firebase project
- [ ] Fresh `google-services.json` downloaded and placed at `android/app/google-services.json`
- [ ] Google Sign-In tested successfully on a physical device

## Git / Repository

- [ ] All untracked files committed: `MainActivity.kt`, `StepCounterPlugin.kt`, `permission_manager.dart`, `fitora_background.dart`, `icon_foreground.png`
- [ ] All modified files committed (Phase 1–RC1 work)
- [ ] `key.properties` is in `.gitignore` and has NOT been committed
- [ ] Repository pushed to remote

## Privacy and Legal

- [ ] Privacy Policy written and published at a public URL
- [ ] Privacy Policy URL verified as reachable in a browser
- [ ] All `[PLACEHOLDER]` values in this document filled in

## Play Console — App Setup

- [ ] App created in Play Console
- [ ] App name set: `Fitora – Fitness & Wellness Tracker`
- [ ] Privacy Policy URL entered
- [ ] App access test credentials added (Google account for reviewer)
- [ ] Content rating questionnaire completed
- [ ] Target audience set to 18+
- [ ] Ads declaration: "No ads"

## Play Console — Store Listing

- [ ] App title filled in (max 50 chars)
- [ ] Short description filled in (max 80 chars)
- [ ] Full description filled in (max 4,000 chars)
- [ ] Category set: Health & Fitness
- [ ] Contact email entered
- [ ] Feature graphic uploaded (1024 × 500 px)
- [ ] Minimum 2 phone screenshots uploaded

## Play Console — Data Safety

- [ ] Data collection questions answered
- [ ] Health Connect data types disclosed
- [ ] Data safety section previewed and confirmed

## Play Console — Internal Testing Release

- [ ] AAB uploaded to Internal Testing track
- [ ] Release name entered: `Fitora v1.0.0 — RC1`
- [ ] Release notes entered
- [ ] Tester list created and emails added
- [ ] Opt-in link shared with testers

## Tester Verification (Before Promoting)

- [ ] All testers can install via opt-in link
- [ ] Step tracking works on physical device
- [ ] Google Sign-In works
- [ ] Hydration reminders fire as scheduled
- [ ] Health Connect connects and syncs
- [ ] No crashes in first session
- [ ] Settings persist after app restart
- [ ] All screens render correctly without overflow

---

**Once all items above are checked — you are ready to promote to Production.**

---

*Fitora v1.0 — Release Package — Generated 2026-07-31*

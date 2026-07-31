# Data Safety Checklist — Fitora v1.0

> This file lists every question from the Google Play **Data Safety** section.
> **Do not guess.** Fill in each answer based on your actual implementation and legal review.
> Incorrect Data Safety declarations can result in app removal.

---

## Section 1 — Data Collection and Security

### 1.1 Does your app collect or share any of the required user data types?

> Data types include: location, personal info, financial info, health & fitness, messages, photos/videos, audio, files, contacts, app activity, web browsing, app info, device identifiers.

- [ ] **Yes** — _(proceed to fill in all sections below)_
- [ ] **No** — _(if selected, all sections below can be left blank)_

### 1.2 Is all of the user data collected by your app encrypted in transit?

- [ ] **Yes**
- [ ] **No**

### 1.3 Do you provide a way for users to request that their data is deleted?

- [ ] **Yes** _(provide method — e.g. in-app option, email request)_
- [ ] **No**

---

## Section 2 — Data Types Collected

> For each data type, indicate: Is it collected? Is it shared with third parties?
> "Collected" = stored on your servers or transmitted off-device (Firebase, analytics, etc.)
> "Shared" = sent to third parties (not including service providers acting on your behalf)

### Personal Info

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Name | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Used for personalization greeting |
| Email address | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Used for Firebase Auth |
| User IDs | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Firebase UID |
| Address | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Phone number | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Race and ethnicity | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Political or religious beliefs | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Sexual orientation | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Other personal info | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |

### Financial Info

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Purchase history | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Credit info | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Other financial info | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### Health & Fitness

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Health info | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Sleep data, calories, exercise |
| Fitness info | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Steps, distance, workouts |

### Location

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Precise location | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Approximate location | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### Messages

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Emails | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| SMS or MMS | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Other in-app messages | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### Photos and Videos

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Photos | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Videos | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### Audio Files

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Voice or sound recordings | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Music files | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |
| Other audio files | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### Files and Docs

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Files and docs | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### App Activity

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| App interactions | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| In-app search history | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Installed apps | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Other user-generated content | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Other actions | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |

### Web Browsing

| Data Type | Collected? | Shared? |
|-----------|-----------|---------|
| Web browsing history | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` |

### App Info and Performance

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Crash logs | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Firebase Crashlytics if enabled |
| Diagnostics | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |
| Other app performance data | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | |

### Device or Other IDs

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Device or other IDs | `[ ] Yes  [ ] No` | `[ ] Yes  [ ] No` | Firebase installation ID |

---

## Section 3 — For Each Collected Data Type

> For each data type you marked "Yes — Collected", answer:

### Purpose of Collection

- [ ] App functionality
- [ ] Analytics
- [ ] Developer communications
- [ ] Advertising or marketing
- [ ] Fraud prevention, security, and compliance
- [ ] Personalization
- [ ] Account management

### Is it required or optional?

- [ ] Required (user cannot use the app without providing it)
- [ ] Optional (user can choose not to provide it)

---

## Section 4 — Sensitive Permissions

> Health Connect data access must be disclosed separately if used.

### Health Connect

- [ ] Does the app access Health Connect data?
  - If yes: List all health data types read from Health Connect:
    - `[ ]` Steps
    - `[ ]` Distance
    - `[ ]` Calories burned
    - `[ ]` Exercise sessions
    - `[ ]` Sleep sessions
    - `[ ]` Other: _______________

---

## Notes for Legal Review

> The following areas should be reviewed by someone with legal knowledge before submission:

- The definition of "collected" vs "processed on-device only" in the context of Fitora's local SQLite storage
- Whether Firebase Auth email storage qualifies as "collected" under Play's definition
- Health Connect data is processed on-device — confirm whether it counts as "collected" if not transmitted to your servers
- Whether the `RECEIVE_BOOT_COMPLETED` permission requires disclosure

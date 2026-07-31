# Android Permissions — Fitora v1.0

> Source: `android/app/src/main/AndroidManifest.xml`  
> Use this document to justify each permission during Play Store review.

---

## Declared Permissions

### `android.permission.ACTIVITY_RECOGNITION`

| Field | Detail |
|-------|--------|
| **Type** | Dangerous permission (requires runtime request) |
| **Android version** | Required from Android 10 (API 29+) |
| **Runtime request** | Yes — shown to user on first launch via permission flow |
| **Justification** | Fitora uses the device's built-in step counter sensor to track daily step count in real time. This permission is required on Android 10 and above to access the step counter and step detector hardware sensors. Without it, step tracking is unavailable. |

---

### `android.permission.POST_NOTIFICATIONS`

| Field | Detail |
|-------|--------|
| **Type** | Dangerous permission (requires runtime request) |
| **Android version** | Required from Android 13 (API 33+) |
| **Runtime request** | Yes — shown to user on first launch via permission flow |
| **Justification** | Fitora sends hydration reminder notifications on a user-configured schedule. This permission is required on Android 13+ to display any notifications. Users can enable or disable reminders at any time in Settings. |

---

### `android.permission.RECEIVE_BOOT_COMPLETED`

| Field | Detail |
|-------|--------|
| **Type** | Normal permission (auto-granted, no dialog) |
| **Android version** | All versions |
| **Runtime request** | No |
| **Justification** | Android cancels all scheduled notifications when the device is rebooted. This permission allows Fitora to automatically reschedule hydration reminders after a device restart so users do not miss their configured reminders. |

---

### `android.permission.VIBRATE`

| Field | Detail |
|-------|--------|
| **Type** | Normal permission (auto-granted, no dialog) |
| **Android version** | All versions |
| **Runtime request** | No |
| **Justification** | Allows Fitora's hydration reminder notifications to vibrate the device in addition to playing a sound, providing a tactile alert for users who keep their phone on silent. |

---

### `android.permission.health.READ_STEPS`

| Field | Detail |
|-------|--------|
| **Type** | Health Connect permission |
| **Requires** | Health Connect app installed |
| **Runtime request** | Yes — via Health Connect permission dialog |
| **Justification** | Read daily step count from Health Connect to merge with on-device sensor data and provide a comprehensive step history in the Progress screen. |

---

### `android.permission.health.READ_DISTANCE`

| Field | Detail |
|-------|--------|
| **Type** | Health Connect permission |
| **Requires** | Health Connect app installed |
| **Runtime request** | Yes — via Health Connect permission dialog |
| **Justification** | Read total distance walked/run from Health Connect to display alongside step data in the Progress analytics dashboard. |

---

### `android.permission.health.READ_TOTAL_CALORIES_BURNED`

| Field | Detail |
|-------|--------|
| **Type** | Health Connect permission |
| **Requires** | Health Connect app installed |
| **Runtime request** | Yes — via Health Connect permission dialog |
| **Justification** | Read active calories burned from Health Connect to display in the Home dashboard and Progress charts, giving users insight into their daily energy expenditure. |

---

### `android.permission.health.READ_EXERCISE`

| Field | Detail |
|-------|--------|
| **Type** | Health Connect permission |
| **Requires** | Health Connect app installed |
| **Runtime request** | Yes — via Health Connect permission dialog |
| **Justification** | Read exercise session records from Health Connect to populate the workout history and weekly activity summaries in the Progress screen. |

---

### `android.permission.health.READ_SLEEP`

| Field | Detail |
|-------|--------|
| **Type** | Health Connect permission |
| **Requires** | Health Connect app installed |
| **Runtime request** | Yes — via Health Connect permission dialog |
| **Justification** | Read sleep session data from Health Connect to display sleep duration and quality in the Health section of the Profile screen. |

---

## Hardware Features Declared

> These are declared with `android:required="false"`, meaning the app can be installed on devices without these sensors. Features are used opportunistically if available.

### `android.hardware.sensor.stepcounter`

- **Required:** `false`
- **Purpose:** The built-in step counter sensor provides cumulative step counts since last device reboot. Fitora uses this for accurate real-time step tracking.

### `android.hardware.sensor.stepdetector`

- **Required:** `false`
- **Purpose:** The step detector sensor fires an event with each detected step. Used as a fallback or supplement to the step counter for more responsive tracking.

---

## Health Connect — Additional Disclosure

> Google Play requires explicit disclosure of Health Connect data access separately from standard permissions.

| Health Data Type | Read | Write | Reason |
|-----------------|------|-------|--------|
| Steps | ✅ | ❌ | Merge with on-device step counter |
| Distance | ✅ | ❌ | Display in Progress dashboard |
| Calories burned | ✅ | ❌ | Display in Home and Progress |
| Exercise sessions | ✅ | ❌ | Populate workout history |
| Sleep sessions | ✅ | ❌ | Display in Health / Profile |

> **Note:** Fitora reads Health Connect data only — it does not write any data back to Health Connect.

---

## Permissions NOT Used

The following common permissions are explicitly **not** requested by Fitora:

| Permission | Reason Not Used |
|------------|-----------------|
| `ACCESS_FINE_LOCATION` | No GPS or location tracking |
| `ACCESS_COARSE_LOCATION` | No location features |
| `CAMERA` | No camera access |
| `READ_CONTACTS` | No contact access |
| `READ_EXTERNAL_STORAGE` | No file system access |
| `RECORD_AUDIO` | No audio recording |
| `INTERNET` | Provided implicitly by Firebase SDK (no explicit declaration needed) |
| `SCHEDULE_EXACT_ALARM` | Not needed — reminders use `inexactAllowWhileIdle` scheduling |

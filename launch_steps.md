# Mama Health Admin — Android Deployment Guide (`launch_steps.md`)

## 1. Project Overview

- **Purpose:** This document is the official deployment checklist for building and releasing the **Mama Health Admin** Flutter application as a production-ready **Android APK**. It documents every mandatory Android configuration, the permissions used, the release checklist, feature-specific requirements, and the pre-release testing plan.
- **Supported platform(s):** Android (primary release target). The app is also developed/tested on Flutter Web (Chrome).
- **Backend:** A remote HTTPS API at `https://mama-health-backend.onrender.com` (Render free tier — cold starts can take 20–50s).
- **Current status:** The Flutter app logic is fully cross-platform and network-ready. This release pass applied the mandatory Android shell configuration (permissions, application ID, signing scaffolding, R8/ProGuard, secure-storage migration path, notification permission) so the project can be built and distributed as an APK.

---

## 2. Mandatory Android Configurations

| What was changed | Why it was required | File modified |
|------------------|---------------------|---------------|
| Added `INTERNET` permission | Android requires an explicit `<uses-permission>` for network access. Without it the app cannot authenticate or load any data on a device. | `android/app/src/main/AndroidManifest.xml` |
| Added `POST_NOTIFICATIONS` permission | Android 13+ (API 33) requires a runtime permission to display notifications. Declared now so future local/FCM notifications work; requested at runtime on API 33+. | `android/app/src/main/AndroidManifest.xml` |
| Set `android:label="Mama Health Admin"` | The launcher must show a proper product name, not the raw template value `"admin"`. | `android/app/src/main/AndroidManifest.xml` |
| Set `android:usesCleartextTraffic="false"` | Explicitly forbid cleartext HTTP. The backend is HTTPS-only; this hardens network security and prevents accidental insecure traffic. | `android/app/src/main/AndroidManifest.xml` |
| Changed `namespace` and `applicationId` to `com.mamahealth.admin` | The default placeholder `com.example.admin` cannot be published to the Play Store and should never be used for a real app. | `android/app/build.gradle.kts` |
| Set `minSdk = 23` | Ensures a modern baseline (Android 6.0+) that supports runtime permissions and the used APIs. | `android/app/build.gradle.kts` |
| Added release signing config block | Release builds must be signed with a private release keystore, not the debug key. The Gradle file reads `android/key.properties` (git-ignored) and falls back to debug signing only when no keystore is configured (for local `--release` dev builds). | `android/app/build.gradle.kts` |
| Enabled R8 code + resource shrinking for release | Reduces APK size and removes unused code for production builds. | `android/app/build.gradle.kts` |
| Added `proguard-rules.pro` | Provides keep rules so Dio/GetX/model classes used via JSON mapping are not stripped by R8. | `android/app/proguard-rules.pro` |
| Moved `MainActivity.kt` to package `com.mamahealth.admin` | The Kotlin package must match the new `namespace`/`applicationId`. | `android/app/src/main/kotlin/com/mamahealth/admin/MainActivity.kt` |
| Added `android/key.properties.example` | Template for the release keystore config; the real `key.properties` is git-ignored for security. | `android/key.properties.example` |
| Updated `.gitignore` | Prevents committing the real keystore (`*.jks`, `*.keystore`) and `key.properties`. | `.gitignore` |

---

## 3. Permissions

| Permission | Why it is required | Feature(s) that use it | Runtime permission? |
|------------|--------------------|------------------------|---------------------|
| `android.permission.INTERNET` | Required for all HTTP(S) API calls to the backend. | Authentication, Dashboard, Patients, Doctors, Appointments, Notifications, SOS, Profile, Reports | No (normal permission, granted at install) |
| `android.permission.POST_NOTIFICATIONS` | Android 13+ gate for displaying notifications. Declared for future local/FCM notifications. The app currently reads the admin notification inbox over the API. | Notifications (broadcast delivery to devices) | **Yes** — request at runtime on API 33+ |

**Not required (assessed):**
- **Location** — the SOS module only *displays* patient coordinates returned by the backend; the admin app does not request device location. No `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` needed.
- **Camera / Media / Storage** — no image upload, camera, or file-storage features exist. Modern scoped storage is sufficient; no permissions needed.
- **Background location / Background services** — not used by the current feature set.

---

## 4. Release Checklist

### AndroidManifest verification
- [x] `INTERNET` permission present
- [x] `POST_NOTIFICATIONS` permission present (for future notifications)
- [x] `usesCleartextTraffic="false"` (HTTPS only)
- [x] Correct launcher label (`Mama Health Admin`)
- [x] `MainActivity` exported (launcher) with launchMode and configChanges intact

### Gradle configuration
- [x] Unique `applicationId` / `namespace` (`com.mamahealth.admin`)
- [x] `minSdk = 23`, `targetSdk` from Flutter
- [x] Java 11 source/target compatibility
- [x] AndroidX enabled (`android.useAndroidX=true` in `gradle.properties`)

### SDK versions
- [x] AGP 8.9.1, Kotlin 2.1.0 (from `settings.gradle.kts`)
- [x] `compileSdk`/`ndkVersion` from Flutter
- [x] Java 11 toolchain

### Release signing
- [x] Signing config wired to read `android/key.properties`
- [ ] **ACTION REQUIRED:** Create a real release keystore and `android/key.properties` (see `key.properties.example`). Until then, release builds fall back to the debug key (development only).
- [x] Keystore + `key.properties` git-ignored

### Network configuration
- [x] HTTPS base URL only (no cleartext)
- [x] `usesCleartextTraffic="false"`
- [x] Dio `ApiClient` configured with token refresh + retry (verify device connectivity/timeouts)

### Notification setup
- [x] `POST_NOTIFICATIONS` declared
- [ ] Not applicable yet: FCM/local-notification channels and runtime request are future work (see §7).

### Token refresh verification
- [x] `AuthInterceptor` auto-refreshes expired access tokens and retries the request on 401
- [x] Only logs out on refresh failure
- [ ] Verify on a physical device that a session survives token expiry and refresh works end-to-end

### Secure storage
- [x] Auth tokens currently stored in `SharedPreferences` (works, but plaintext)
- [ ] **RECOMMENDED:** Migrate token storage to Android Keystore-backed storage (`flutter_secure_storage`) before production distribution

### API endpoint verification
- [x] All endpoints referenced from `ApiConstants` (no hardcoded URLs)
- [x] Base URL = `https://mama-health-backend.onrender.com` (HTTPS)
- [ ] Verify all feature endpoints respond from the device network

### Environment configuration
- [x] No hardcoded secrets/API keys in the app
- [ ] Confirm backend CORS/permissions allow the Android app (same HTTPS origin)

### Debug log removal
- [x] Extensive `debugPrint` present (development aid)
- [ ] **RECOMMENDED:** Gate `debugPrint` behind `kReleaseMode` so release builds emit no verbose logs

### Performance optimizations
- [x] R8 code shrinking enabled for release
- [x] Resource shrinking enabled for release
- [x] `proguard-rules.pro` added
- [ ] Optional: app icon replacement, splash branding, ABI splits to reduce APK size

### Final testing
- [ ] Build `flutter build apk --release`
- [ ] Install on a physical device and run the full smoke test (§6)

---

## 5. Feature-Specific Requirements

| Module | Requirement | Status |
|--------|-------------|--------|
| **Authentication** | Token storage (SharedPreferences → secure). Auto-refresh + retry on 401. Logout clears tokens and navigates to login. | Functioning; secure-storage migration recommended. |
| **Dashboard** | Requires `INTERNET`. Uses HTTPS stats endpoint. | Complete. |
| **Patients** | Requires `INTERNET`; CRUD via HTTPS. No image upload (network image currently commented out). | Complete. |
| **Doctors** | Requires `INTERNET`; list/detail/invite via HTTPS. | Complete. |
| **Appointments** | Requires `INTERNET`; book/list/status via HTTPS. | Complete. |
| **Notifications** | Reads admin inbox via HTTPS. `POST_NOTIFICATIONS` declared for future pushed broadcasts. | API complete; push delivery is future work. |
| **Broadcast messaging** | Admin `POST /notifications/broadcast/` (async, 202). No device permission needed to send. | Complete. |
| **Profile** | `GET/PATCH auth/me` + change password via HTTPS. Password values are intentionally not logged. | Complete. |
| **Password changes** | Requires auth; auto-refresh on 401 handled. | Complete. |
| **SOS** | Displays backend-provided patient coordinates; resolves/marks false alarm via HTTPS. No device location permission needed. | Complete. |
| **Reports** | Admin stats/search via HTTPS. | Complete. |

---

## 6. Testing Before APK Generation

Run the following on a physical Android device (release build) before generating the final APK:

- [ ] **Install & launch:** App installs, opens to the login screen, no crash.
- [ ] **Authentication:** Login succeeds; access + refresh tokens stored; session persists after app restart; logout clears session and returns to login.
- [ ] **Token refresh:** With a short-lived token, perform an action after expiry and confirm the app auto-refreshes and retries (no spurious logout).
- [ ] **Dashboard:** Stats, chart, and recent-activity load over the network.
- [ ] **Patients:** List, detail, register patient, assign doctor all work.
- [ ] **Doctors:** List, detail, invite a doctor work.
- **Appointments:** List and manage appointments (book/reschedule/status).
- **Notifications:** Inbox loads; filters work; mark-all-read works; open a notification detail; compose + send a broadcast.
- **Profile:** View/edit profile; change password (auto-refresh path).
- **SOS:** List events; open detail; resolve and mark false-alarm.
- **Empty/error states:** Force airplane mode and verify each screen shows a friendly error + retry (no crash).
- **Data safety:** Confirm no sensitive data is left in logs on the device.
- **Permissions:** On Android 13+, confirm the notification permission prompt appears when relevant (if notifications are enabled).
- **Performance:** Cold start acceptable; scrolling is smooth; no jank.

---

## 7. Future Improvements (not mandatory for initial release)

- **Secure token storage:** Migrate from `SharedPreferences` to `flutter_secure_storage` (Android Keystore-backed) for stronger protection of JWTs.
- **Live push notifications:** Add `firebase_messaging` + `flutter_local_notifications`, create notification channels, and request `POST_NOTIFICATIONS` at runtime on Android 13+. This would enable real-time broadcast delivery to devices.
- **Branded launcher icon:** Replace the default Flutter icon with a proper adaptive icon (foreground/background).
- **Branded splash screen:** Configure a custom Android 12+ splash.
- **Explicit versioning:** Set explicit `versionCode`/`versionName` in Gradle for Play Store control.
- **Log hygiene:** Gate `debugPrint` behind `kReleaseMode` to strip verbose dev logs from release builds.
- **ABI splits / app bundle:** Build an Android App Bundle (AAB) with ABI splits to reduce download size.
- **Deep linking:** Add App Links only if the backend emails clickable magic links (password reset / doctor invite acceptance).
- **CI/CD:** Add a release build pipeline (e.g., GitHub Actions) with signing secrets.

---

*End of deployment guide. This project is now configured for Android release; complete the signing keystore and run the §6 device tests before generating the production APK.*

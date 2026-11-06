# BudgetBook

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase phone sign-in

Enable **Phone** as a sign-in provider in Firebase Authentication. Web apps must
also authorize the host domain in Firebase Authentication; Firebase Auth uses
reCAPTCHA for web phone verification.

Android initializes Firebase from `android/app/google-services.json`; no Firebase
Dart defines are needed when running the Android app. Web and platforms without
native Firebase configuration initialize with platform-specific public client
options passed as Dart defines. Supply these values when running or building
those platforms:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID` (use the app ID for the target platform)
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN` (optional; defaults to
  `<project-id>.firebaseapp.com`)
- `FIREBASE_IOS_BUNDLE_ID` (iOS)
- `FIREBASE_ANDROID_CLIENT_ID` (optional)
- `FIREBASE_IOS_CLIENT_ID` (optional)
- `FIREBASE_MEASUREMENT_ID` (optional, web)

For example, run Web with:

```sh
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=<api-key> \
  --dart-define=FIREBASE_APP_ID=<web-app-id> \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> \
  --dart-define=FIREBASE_PROJECT_ID=<project-id>
```

Android also needs the Firebase-generated `android/app/google-services.json`
because the Android Google Services Gradle plugin is enabled. Register the
Android app's SHA-1/SHA-256 fingerprints in Firebase for phone authentication.
Do not commit service-account credentials.

After Firebase confirms the SMS code, the app obtains the Firebase ID token and
posts it to `https://api.budgetbook.in/api/v1/auth/firebase/verify` with the
entered name as `full_name`. The backend access token from that response is
stored for subsequent API calls.

## Application maintenance mode

Maintenance is controlled from **Firebase Console > Remote Config > Add
parameter**. Create these parameters:

| Parameter key | Type | Default |
| --- | --- | --- |
| `maintenance_mode` | Boolean | `false` |
| `maintenance_title` | String | `We'll Be Back Soon!` |
| `maintenance_message` | String | `We're currently performing scheduled maintenance to improve your experience. Please check back soon.` |
| `maintenance_button_text` | String | `Try Again` |

Publish the parameter changes, then enable maintenance by setting
`maintenance_mode` to `true`. Publish again and set it to `false` to restore
normal navigation. Installed apps fetch the configuration at launch and when
they return to the foreground. Firebase real-time Remote Config updates are
also handled when available. Fetches are cached for 15 minutes in production;
Firebase may delay delivery due to caching and Remote Config throttling.

For testing, call the console's real-time changes preview and use a debug build.
If an app cannot reach Firebase, it uses the last successfully activated
configuration. On a first installation with no cached activation, it uses the
safe defaults with `maintenance_mode` set to `false`. Offline Remote Config
failure therefore does not block startup. Firebase initialization and fetch
operations are bounded by startup/fetch timeouts.

# Wiring in the native + backend code

This covers everything native/backend: OS permissions, the core app-blocking
mechanism, real installed-app detection, and the Firebase-based Co-Keeper
backend.

## 1. Generate the native scaffolding (one-time)

```
flutter create .
flutter pub get
```

Safe to run on an existing project -- fills in missing platform folders
without touching `lib/` or `pubspec.yaml`.

## 2. Copy in the native Kotlin files

All paths below are relative to `android/app/src/main/`.

| From (this folder)                              | To                                                                 |
|---------------------------------------------------|---------------------------------------------------------------------|
| `kotlin/MainActivity.kt`                          | `kotlin/<your/package/path>/MainActivity.kt` (replace the generated one) |
| `kotlin/OneirAccessibilityService.kt`             | same `kotlin/<your/package/path>/` folder                          |
| `kotlin/InterruptionActivity.kt`                  | same `kotlin/<your/package/path>/` folder                          |
| `xml/oneir_accessibility_service_config.xml`      | `res/xml/oneir_accessibility_service_config.xml` (create the `xml` folder) |

Check the `package com.oneir.app` line at the top of each `.kt` file matches
whatever package `flutter create .` actually used -- update all three if
different.

## 3. Update AndroidManifest.xml and strings.xml

- Add everything in `AndroidManifest_additions.xml` into
  `android/app/src/main/AndroidManifest.xml`, in the places commented
  (permissions, `<queries>`, the service, the activity, the Dart-entrypoint-args
  meta-data).
- Add the string from `xml/strings_additions.xml` into
  `android/app/src/main/res/values/strings.xml`.

## 4. Set up Firebase (needed for the real Co-Keeper backend)

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
   if you don't have one.
2. Install the FlutterFire CLI and run it from the project root:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and wires up the Android app
   automatically -- pick the project you just created, and Android as the
   platform.
3. In the Firebase Console, enable **Firestore** (start in production mode)
   and **Cloud Messaging**.
4. Deploy the security rules and the Cloud Function:
   ```
   npm install -g firebase-tools
   firebase login
   firebase init firestore functions   # point it at the existing firestore.rules and functions/ folder in this project
   firebase deploy --only firestore:rules,functions
   ```
   The Cloud Function requires the Blaze (pay-as-you-go) plan -- the free
   Spark plan doesn't support Cloud Functions. Firestore itself has a free
   tier that's plenty for testing.
5. `lib/main.dart` already calls `Firebase.initializeApp()` and registers
   the device for push on startup -- once `firebase_options.dart` exists,
   it'll just work.

## 5. Rebuild

```
flutter pub get
flutter run
```

## What's real now

- **`OneirAccessibilityService`** detects protected-app opens system-wide
  (event-driven) and launches a real interruption screen on top of them.
- **The interruption screen is graduated**, per the Co-Keeper philosophy
  doc: 1st same-day attempt on an app shows a simple check-in, 2nd shows an
  intention/five-more-minutes check, 3rd+ escalates to the full Co-Keeper
  gate. Attempt counts and today's intention (pulled from your first
  unchecked Widgets task) are both real and persisted.
- **"Request Key" sends a real Firestore request** to your paired Co-Keeper,
  who gets a real push notification and can Approve/Decline from the
  `CoKeeperInboxScreen` (not yet wired into app navigation -- see below) on
  their own device. The requester's screen updates live when they respond.
- **Protected Apps** now shows your phone's actual installed, launchable
  apps (with real icons) via `PackageManager`, not a hardcoded list.
- **Persistence**: your name, Widgets task check-state, and onboarding
  completion all survive an app restart -- a returning user goes straight to
  Home instead of sitting through onboarding again.
- **Display Over Apps / Notifications** trigger real OS permission dialogs.
- **Accessibility** sends you to real Settings and auto-detects when enabled.

## What's still not fully finished

- **`CoKeeperInboxScreen` isn't reachable from anywhere yet** -- there's no
  navigation entry point or deep-link handling for someone to actually open
  it. It works if you navigate to it directly (e.g. temporarily set it as
  `home:` in `main.dart` on the Co-Keeper's test device), but needs a real
  entry point: either a Settings menu item, or (better, per the invite flow)
  a proper deep link so tapping the invite link opens straight to an Accept
  screen. Deep linking itself isn't implemented.
- **The invite link uses a placeholder domain** (`oneir.app`) that doesn't
  exist -- needs either a real hosted page or a Firebase Dynamic Link before
  it does anything for whoever receives it.
- **No reason picker** (Homework/Urgent/Other) on the request -- it currently
  sends a blank reason. Easy to add to the full-gate stage's UI.
- **The interruption screen's art is still placeholder** (a generic paw
  icon) -- swap in the real Vanya check-in/thinking/speak animations once
  you share those assets.
- **This all relies on each device's self-generated local ID as if it were
  a user account** (see the note at the top of `firestore.rules`) -- there's
  no real login, so anyone who has (or guesses) a request/pairing document ID
  could theoretically read or interfere with it. Fine for trusted use among
  people who already know each other; would need real Firebase Auth before
  handling anything more sensitive.
- **Battery-optimization exemption** (the 5th permission from the original
  Permissions spec) still isn't requested anywhere.

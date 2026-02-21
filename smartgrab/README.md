# SmartGrab

SmartGrab is an Android-first decision-assist app for gig workers. It reads on-screen offers from DoorDash and Instacart (via Android Accessibility Services), scores them locally, and surfaces a recommendation via notification + overlay in seconds.

## Features
- Real-time offer detection from supported gig apps
- Configurable decision engine (min pay, max distance, cost per km)
- Recommendation overlays + notifications
- Firebase Auth + Firestore user profiles and admin metrics
- Admin dashboard with user activity stats

## Tech Stack
- Flutter (Dart)
- Android Accessibility Service (Kotlin)
- Firebase Auth + Firestore
- GitHub Actions CI/CD
- Docker (repeatable build/test environment)

## Project Structure
- `smartgrab/` — Flutter app + Android native code
- `.github/workflows/ci.yml` — CI pipeline
- `Dockerfile` — containerized build environment

## Setup
### Prerequisites
- Flutter SDK (3.38.9)
- Android Studio / Android SDK
- Firebase project with Authentication + Firestore enabled

### Firebase config
1. Add an Android app in Firebase with package name: `com.smartgrab.app`
2. Download `google-services.json`
3. Place it at: `smartgrab/android/app/google-services.json`

### Run the app
```bash
cd smartgrab
flutter pub get
flutter run -d <device_id>
```

## Permissions (Android)
SmartGrab requires the following permissions to work:
- Accessibility Service (screen parsing)
- Overlay permission (recommendation bubble)
- Notifications

## Admin Access
Admin access is controlled in Firestore:
- Collection: `admins`
- Document ID: `<user UID>`
- Fields: `email`

For development, you can set your email in `lib/main.dart`:
```dart
const bootstrapAdminEmail = 'admin@smartgrab.com';
```

## CI/CD
A GitHub Actions workflow runs on every push/PR:
- `flutter analyze`
- `flutter test`

## Docker
Build and run locally:
```bash
docker build -t smartgrab .
docker run --rm smartgrab
```

## Security Note
`google-services.json` is not committed to the repo and must remain local.

## Disclaimer
This app uses Accessibility Services to read UI content. Users are responsible for complying with app terms of service.

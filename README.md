# Clinic App

A Flutter application for managing a medical practice: patient archive, waiting room, appointments, billing, statistics, and printable prescriptions (A5 PDF).

## Features
- Separate doctor and receptionist interfaces
- Patient archive with search by name or phone number
- Waiting room management
- Appointment booking with a daily limit
- Billing and payment tracking
- Statistics by period (today, week, month, year) with simple charts
- Printable A5 prescriptions with Arabic (RTL) support
- Light / dark mode

## Tech Stack
- [Flutter](https://flutter.dev)
- Firebase Authentication and Cloud Firestore
- `pdf` and `printing` packages for prescription generation

## Getting Started

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone the repository and run:
   ```bash
   flutter pub get
   ```
3. Create a Firebase project and enable **Email/Password authentication** and **Cloud Firestore**.
4. Generate the Firebase configuration:
   ```bash
   flutterfire configure
   ```
   Alternatively, copy `lib/firebase_options.example.dart` to `lib/firebase_options.dart` and replace the placeholder values.
5. For Android, place your `google-services.json` in `android/app/`.
6. Customize the practice details in the `ClinicInfo` class (`lib/screens/prescription_screen.dart`) and replace `assets/images/logo.png` with your own logo.
7. Run the app:
   ```bash
   flutter run
   ```

## Build
```bash
flutter build windows --release
flutter build apk --release
```

## Security
Firebase configuration files are intentionally excluded from version control (see `.gitignore`). Before any real-world use, configure strict Firestore security rules (for example `request.auth != null`) and never commit real patient data.

## Disclaimer
This project is provided as-is and is not a certified medical device. Make sure it complies with the data protection regulations that apply in your country before storing real patient information.

# Income & Expenses

A Flutter application for managing daily income, expenses, payable accounts, and receivable accounts.

## Features

- Dashboard with net balance, income, and expenses
- Bank and Cash accounts
- Payable accounts for amounts owed
- Receivable accounts for amounts to receive
- Add and manage transactions
- Account transaction reports
- PDF report sharing
- WhatsApp message sharing
- Local SQLite database

## Requirements

- Flutter SDK (stable channel)
- Dart SDK compatible with the Flutter version
- Android SDK for local Android builds

## Setup

Install Flutter dependencies:

```bash
flutter pub get
```

Check the Dart code:

```bash
flutter analyze
```

Build the release APK:

```bash
flutter build apk --release
```

## APK Output

After a successful build, the APK will be available at:

`build/app/outputs/flutter-apk/app-release.apk`

## Cloud Build

This project uses `codemagic.yaml` for automated Android APK builds through Codemagic.

## Important

The project must include the complete Flutter Android project structure,
including the `android/` directory.

Do not delete application data or uninstall an existing app if you need
to preserve its locally stored transaction history.

## License

All rights reserved unless a separate license is provided.

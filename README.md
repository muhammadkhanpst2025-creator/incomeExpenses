# Income & Expenses

Flutter khata and money-management app for daily income, expenses, Bank/Cash, Payable and Receivable accounts.

## Updated functions

- Opening balance and opening date are editable for new and existing accounts.
- Account balance is recalculated from opening balance plus saved transactions after every transaction add, edit, or delete.
- Existing SQLite database is upgraded in place (database version 4); tables are not dropped.
- Payable and Receivable outstanding totals are shown separately on the account form.
- Account categories include common options and allow a custom category.
- Account can be activated, deactivated, or deleted. Accounts with transaction history are deactivated rather than physically removed.
- Payable payment form shows account, category, current outstanding balance, amount, Bank/Cash payment destination, date, and remarks.
- Account statements support a from/to date range and show opening, CR, DR, running balance, and closing balance; PDF and WhatsApp sharing are available.
- Currency display uses Pakistani Rupees (`Rs`).
- Wallet launcher icon is generated from `assets/wallet.png` using `flutter_launcher_icons`.

## Build with Codemagic

The repository root must contain `pubspec.yaml`, `codemagic.yaml`, and `lib/`. The workflow generates the Android platform folder if it is missing.

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Important data safety

Do not uninstall the existing app when you need its local khata data. Install the new APK as an update using the same Android application ID and compatible signing key. Database migration upgrades the existing `sahil_khata.db` database without deleting account or transaction rows. Always make a backup before installing a major update.

Developer: **SAHIL JANWERY**

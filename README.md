# Income & Expenses
Flutter app for daily income, expenses, wallet accounts, payable/receivable khata, and account reports.

## Launcher icon
`assets/wallet.png` is the chosen wallet icon. `flutter_launcher_icons` generates the Android launcher icon during the cloud build. If Android icon files are regenerated manually, run `dart run flutter_launcher_icons` after `flutter pub get`.

## Cloud build (Codemagic)
Connect this repository in Codemagic and use the included `codemagic.yaml`. It creates the `android/` folder if missing, resolves dependencies, generates the icon, analyzes code and builds a release APK. Download the artifact named `app-release.apk` from a successful build.

## Local commands
```bash
flutter pub get
dart run flutter_launcher_icons
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --release
```

## Existing data
The database file remains named `sahil_khata.db`; the existing schema is retained in this update. Do not uninstall the previous app when preserving its local database. Android upgrades must also use the same application ID/signing setup to update in place.

## Developer
Developed by SAHIL JANWERY.

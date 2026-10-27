# IDS mobile app

Flutter app for Android and iOS, named IDS, with the existing IDS logo on its
login screen and launcher icons. Docket forms, signatures, uploads, groups,
chat, and cloud archiving
remain planned in [the project requirements](../min-requirement.txt).

From the repository root:

```sh
cd mobile_app
flutter pub get
flutter devices
flutter run
```

Start an Android emulator or iOS simulator, or connect a phone, before running
the app. If multiple devices are available, use `flutter run -d <device-id>`.

The project was generated with Flutter 3.41.7 and Dart 3.11.5. Its main files are:

```text
lib/main.dart           App entry point and theme
lib/login_page.dart     Email, demo OTP, and sign-out screens
lib/login_permissions.dart  Camera/location permission channel
assets/images/          IDS logo, reused from the website's favicon.jpg
android/                Android project
ios/                    iOS project
pubspec.yaml            App metadata and dependencies
pubspec.lock            Locked dependency versions
```

For Android, use JDK 21 with the generated Gradle 8.14 wrapper. The local
Android Studio installation currently bundles Java 25, which is incompatible
with that wrapper. Once JDK 21 is installed, select its home directory for
Flutter with `flutter config --jdk-dir=<jdk-21-home>`. See the
[Gradle Java compatibility table](https://docs.gradle.org/current/userguide/compatibility.html#java_runtime).

For iOS, use Xcode and an iOS 17.0 or newer simulator/device. The project,
Runner, RunnerTests, and Flutter app framework metadata use a 17.0 minimum
in every build configuration. Keep that minimum when editing Xcode settings.

## Demo login

Allow camera and location access. Location access is requested only while
using the app; approximate location is accepted. If access is denied, the
login page stays open and provides a retry or **Open settings** action for
blocked access.

Before opening OTP verification, the app checks the entered email against the
`accounts` collection in the `ids-service-docket` Cloud Firestore project.
The `email` field is matched case-insensitively. The admin email
`admin@megascreen.com.my` bypasses this lookup. Other emails must already be
listed by IDS Admin.

Enter `888888` on the verification screen. Incorrect codes are rejected.
**Resend OTP** clears the code field and displays the demo code again. No
email is sent. **Change email** returns to login, and **Sign out** clears the
temporary session. Camera images and coordinates are not collected by this
login flow. Real email delivery and production authentication are future work.

## Building from Xcode

Run the dependency setup from `mobile_app/` before opening Xcode:

```sh
flutter pub get
flutter build ios --config-only
open ios/Runner.xcworkspace
```

Keep `.dart_tool/package_config.json` and `ios/Flutter/Generated.xcconfig`
after setup; Xcode's Flutter script needs these generated files. If a build
ends with `Command PhaseScriptExecution failed with a nonzero exit code`,
inspect the first error above that summary. The previously reported failure
was a missing `.dart_tool/package_config.json`; `flutter pub get` restores it.

To check the Dart code:

```sh
flutter analyze
flutter test
```

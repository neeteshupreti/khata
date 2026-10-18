#!/bin/sh
# One-time setup: generates the Android/iOS platform folders around the Dart
# code in lib/, then applies the Khata settings:
#   - launcher name "खाता"
#   - package name com.khata.app
#   - no splash (plain white launch screen)
# Run from the project root:  sh setup.sh
set -e

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

# flutter create must not touch our own files, so back them up first.
rm -rf .khata_backup && mkdir .khata_backup
cp -r lib .khata_backup/lib
cp pubspec.yaml .khata_backup/pubspec.yaml

flutter create --org com.khata --project-name khata --platforms=android,ios .

rm -rf lib && cp -r .khata_backup/lib lib
cp .khata_backup/pubspec.yaml pubspec.yaml
rm -rf .khata_backup
rm -f test/widget_test.dart   # default counter-app test no longer applies

# ---- Package name: com.khata.khata -> com.khata.app
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && sed -i.bak 's/com\.khata\.khata/com.khata.app/g' "$f" && rm -f "$f.bak"
done
OLD_DIR=$(find android/app/src/main -type d -path '*com/khata/khata' | head -n 1)
if [ -n "$OLD_DIR" ]; then
  NEW_DIR=$(dirname "$OLD_DIR")/app
  mkdir -p "$NEW_DIR"
  for k in "$OLD_DIR"/*; do
    sed 's/com\.khata\.khata/com.khata.app/g' "$k" > "$NEW_DIR/$(basename "$k")"
  done
  rm -rf "$OLD_DIR"
fi
# iOS bundle id (if present)
[ -f ios/Runner.xcodeproj/project.pbxproj ] && \
  sed -i.bak 's/com\.khata\.khata/com.khata.app/g' ios/Runner.xcodeproj/project.pbxproj && \
  rm -f ios/Runner.xcodeproj/project.pbxproj.bak

# ---- Launcher name
sed -i.bak 's/android:label="[^"]*"/android:label="खाता"/' android/app/src/main/AndroidManifest.xml
rm -f android/app/src/main/AndroidManifest.xml.bak
[ -f ios/Runner/Info.plist ] && \
  sed -i.bak '/<key>CFBundleDisplayName<\/key>/{n;s/<string>.*<\/string>/<string>खाता<\/string>/;}' ios/Runner/Info.plist && \
  rm -f ios/Runner/Info.plist.bak

# ---- No splash: plain white launch window, and a blank Android 12+ system splash
mkdir -p android/app/src/main/res/values-v31
cat > android/app/src/main/res/values-v31/styles.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">#FFFFFF</item>
        <item name="android:windowSplashScreenAnimatedIcon">@android:color/transparent</item>
        <item name="android:windowBackground">@android:color/white</item>
    </style>
</resources>
XML

flutter pub get
echo ""
echo "Done. Connect a device and run:  flutter run"

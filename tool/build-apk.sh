#!/usr/bin/env bash
# Release build for the appstore: arm64-only.
#
# `flutter build apk --release` alone bundles every ABI (arm64-v8a +
# armeabi-v7a + x86_64) into one fat APK (~106MB). The appstore publishes a
# single universal APK per version and every supported device is aarch64, so
# we restrict the Flutter target platform to arm64 (~37MB).
#
# For emulator/x86_64 debugging build locally WITHOUT --target-platform.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

export ANDROID_HOME="${ANDROID_HOME:-/home/user/Android/sdk}"
export JAVA_HOME="${JAVA_HOME:-/opt/tools/mise/installs/java/17.0.2}"

/home/user/flutter/bin/flutter build apk --release \
  --target-platform android-arm64

echo
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
ls -la build/app/outputs/flutter-apk/app-release.apk
sha256sum build/app/outputs/flutter-apk/app-release.apk

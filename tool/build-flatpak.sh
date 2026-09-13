#!/usr/bin/env bash
# Build the standalone agent app as a self-contained Flatpak bundle.
#
# This does NOT use flatpak-builder (which needs bubblewrap/namespaces that a
# dev pod may forbid). Instead it drives `flatpak build-init / build-finish /
# build-export / build-bundle` directly and assembles the app files itself.
#
# Prereqs:
#   * A glibc host with the Flutter Linux toolchain (see tool/build-appimage.sh
#     for the clang wrapper + extracted libmpv). Alpine/musl is unsupported.
#   * `flatpak` CLI (this script can use an out-of-tree copy; see FLATPAK).
#   * Extracted libmpv closure in MPV_ROOT (fullroot).
#   * The org.freedesktop.Platform 24.08 + Sdk runtimes already installed in the
#     user's FLATPAK_USER_DIR (the bundle references them and pulls them from
#     flathub on install).
#
# Output: /tmp/opencode/Agent.flatpak
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${DIR}/.." && pwd)"

FLUTTER_BIN="${FLUTTER_BIN:-/home/user/flutter/bin}"
TOOLCHAIN="${TOOLCHAIN:-/tmp/opencode/toolchain/bin}"
PKG_CONFIG_DIR="${PKG_CONFIG_DIR:-/tmp/opencode/mpv/pc}"
FULLROOT="${FULLROOT:-/tmp/opencode/mpv/fullroot}"
PATCHELF="${PATCHELF:-/tmp/opencode/appimage/squashfs-root/usr/bin/patchelf}"
FLATPAK="${FLATPAK:-flatpak}"
RUNTIME_VERSION="${RUNTIME_VERSION:-24.08}"
OUT="${OUT:-/tmp/opencode/Agent.flatpak}"
WORK="${WORK:-/tmp/opencode/flatpak-build}"
APP_ID="abcp.sdk.agent_app"
USER_DIR="${FLATPAK_USER_DIR:-$HOME/.local/share/flatpak}"

echo "==> 1/6 flutter build linux --release"
( cd "${APP_ROOT}" && PATH="${FLUTTER_BIN}:${TOOLCHAIN}:$PATH" \
  PKG_CONFIG_PATH="${PKG_CONFIG_DIR}" flutter build linux --release )
BUNDLE="${APP_ROOT}/build/linux/x64/release/bundle"

echo "==> 2/6 assemble app files (bin/ + share/)"
AF="${WORK}/files"
rm -rf "${WORK}" && mkdir -p "${AF}/bin" "${AF}/share/applications" \
  "${AF}/share/icons/hicolor/256x256/apps"
cp -a "${BUNDLE}/agent_app" "${AF}/bin/"
cp -a "${BUNDLE}/data" "${AF}/bin/"
cp -a "${BUNDLE}/lib" "${AF}/bin/"

# libmpv + its closure. Libs the RUNTIME already provides (GTK, etc.) are NOT
# bundled so the runtime ABI stays authoritative; GPU/GL comes from the runtime's
# GL extension + host DRI.
#
# EXCEPTION — ffmpeg: the org.freedesktop.Platform 24.08 runtime ships an OLDER
# ffmpeg (libavutil.so.59 without `av_dovi_find_level`) than the libmpv we link
# against (from FULLROOT). Mixing them makes libmpv fail at startup with:
#   symbol lookup error: libmpv.so.2: undefined symbol: av_dovi_find_level,
#   version LIBAVUTIL_59
# So the libav*/libsw* set is bundled from FULLROOT and kept internally
# consistent ($ORIGIN rpath makes libmpv load ours first).
RF="${USER_DIR}/runtime/org.freedesktop.Platform/x86_64/${RUNTIME_VERSION}/active/files"
# The AppImage build already computed a proven-complete mpv/ffmpeg closure
# (fullclosure). Reuse it as a LAST-RESORT source for libs the runtime lacks and
# FULLROOT never extracted (e.g. libblas/liblapack, pulled by ffmpeg's sphinx).
FULLCLOSURE="${FULLCLOSURE:-/tmp/opencode/fullclosure}"
resolve() { for d in "${FULLROOT}/usr/lib/x86_64-linux-gnu" \
    "${FULLCLOSURE}" \
    "${RF}/lib/x86_64-linux-gnu" /usr/lib/x86_64-linux-gnu; do
    [ -e "$d/$1" ] && { echo "$d/$1"; return; }; done; echo MISSING; }
declare -A seen
for seed in libmpv.so.2 libass.so.9 libplacebo.so.349 \
    libavcodec.so.61 libavutil.so.59 libavformat.so.61 \
    libavfilter.so.10 libavdevice.so.61 libswresample.so.5 libswscale.so.8 \
    libblas.so.3 liblapack.so.3; do
  cp -L "$(resolve "$seed")" "${AF}/bin/lib/"; seen[$seed]=1
done
for _ in $(seq 1 40); do
  grew=0
  for lib in "${AF}/bin/lib/"*.so*; do
    while read -r n; do
      [ -z "$n" ] && continue
      case "$n" in libc.so*|libm.so*|libpthread*|libdl*|librt*|libgcc_s*|libstdc++*|ld-linux*) continue;; esac
      [ -n "${seen[$n]:-}" ] && continue
      seen[$n]=1
      { [ -e "${RF}/lib/x86_64-linux-gnu/$n" ] || [ -e "${RF}/lib/$n" ]; } && continue
      f="$(resolve "$n")"; [ "$f" = MISSING ] && continue
      cp -L "$f" "${AF}/bin/lib/" && grew=1
    done < <(readelf -d "$lib" 2>/dev/null | awk '/NEEDED/{print $5}' | tr -d '[]')
  done
  [ "$grew" = 0 ] && break
done

# Normalize RUNPATHs: the exe must find lib/, and every .so must resolve its
# siblings relative to itself ($ORIGIN). Removes build-time paths baked in by
# the media_kit clang wrapper.
if [ -x "${PATCHELF}" ]; then
  "${PATCHELF}" --set-rpath '$ORIGIN/lib' "${AF}/bin/agent_app"
  for so in "${AF}/bin/lib/"*.so*; do
    "${PATCHELF}" --set-rpath '$ORIGIN' "$so" 2>/dev/null || true
  done
fi

cat > "${AF}/share/applications/${APP_ID}.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Agent
Comment=Standalone ABC agent chat client
Exec=agent_app
Icon=${APP_ID}
Categories=Network;InstantMessaging;
Terminal=false
DESK
cp "${APP_ROOT}/web/icons/Icon-192.png" \
   "${AF}/share/icons/hicolor/256x256/apps/${APP_ID}.png" 2>/dev/null || true

echo "==> 3/6 build-init + place files"
BD="${WORK}/build"
"${FLATPAK}" build-init --arch=x86_64 "${BD}/app" "${APP_ID}" \
  org.freedesktop.Sdk org.freedesktop.Platform "${RUNTIME_VERSION}" >/dev/null
rm -rf "${BD}/app/files"
mkdir -p "${BD}/app/files"
cp -a "${AF}/bin" "${BD}/app/files/"
cp -a "${AF}/share" "${BD}/app/files/"

echo "==> 4/6 build-finish"
cat > "${BD}/app/metadata" <<META
[Application]
name=${APP_ID}
runtime=org.freedesktop.Platform/x86_64/${RUNTIME_VERSION}
sdk=org.freedesktop.Sdk/x86_64/${RUNTIME_VERSION}
META
"${FLATPAK}" build-finish --command=agent_app \
  --share=network --socket=x11 --socket=wayland --socket=pulseaudio \
  --device=dri --filesystem=home --filesystem=host \
  "${BD}/app"

echo "==> 5/6 build-export"
REPO="${WORK}/repo"
"${FLATPAK}" build-export --arch=x86_64 --no-update-summary "${REPO}" "${BD}/app"

echo "==> 6/6 build-bundle"
rm -f "${OUT}"
"${FLATPAK}" build-bundle --arch=x86_64 \
  --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
  "${REPO}" "${OUT}" "${APP_ID}"
ls -la "${OUT}"
sha256sum "${OUT}"

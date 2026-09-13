#!/usr/bin/env bash
# Build a FULLY self-contained Linux AppImage of the standalone agent app.
#
# Self-contained = the AppImage bundles GTK3/GLib/Pango/Cairo/gdk-pixbuf, the
# mpv/ffmpeg dependency closure (241 libs), and the NotoSansSC font. The target
# machine needs NO system libraries beyond glibc.
#
# Build host requirements (this dev pod has them, extracted out-of-tree):
#   * Flutter SDK + a glibc distro (Alpine/musl is NOT supported by the Flutter
#     Linux engine).
#   * clang++ wrapper at /tmp/opencode/toolchain/bin (delegates to system g++
#     with the extracted mpv/GTK dev headers) + PKG_CONFIG_PATH pointing at
#     /tmp/opencode/mpv/pc.
#   * /tmp/opencode/mpv/root and /tmp/opencode/mpv/fullroot: extracted libmpv,
#     libepoxy, X11/EGL headers and their runtime dependency .deb closure.
#   * appimagetool (extracted, no FUSE): /tmp/opencode/appimage/squashfs-root.
#
# Produces /tmp/opencode/Agent-x86_64.AppImage.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../flutter/tool
APP_ROOT="$(cd "${DIR}/.." && pwd)"                    # .../flutter

FLUTTER_BIN="${FLUTTER_BIN:-/home/user/flutter/bin}"
TOOLCHAIN="${TOOLCHAIN:-/tmp/opencode/toolchain/bin}"
PKG_CONFIG_DIR="${PKG_CONFIG_DIR:-/tmp/opencode/mpv/pc}"
MPV_ROOT="${MPV_ROOT:-/tmp/opencode/mpv/root}"
FULLROOT="${FULLROOT:-/tmp/opencode/mpv/fullroot}"
APPIMAGETOOL="${APPIMAGETOOL:-/tmp/opencode/appimage/squashfs-root/usr/bin/appimagetool}"
APPIMAGETOOL_BIN="${APPIMAGETOOL_BIN:-/tmp/opencode/appimage/squashfs-root/usr/bin}"
OUT="${OUT:-/tmp/opencode/Agent-x86_64.AppImage}"
WORK="${WORK:-/tmp/opencode}"
APPDIR="${APPDIR:-${WORK}/AppDir}"
CLOSURE="${WORK}/fullclosure"

echo "==> 1/5 flutter build linux --release"
( cd "${APP_ROOT}" && PATH="${FLUTTER_BIN}:${TOOLCHAIN}:$PATH" \
  PKG_CONFIG_PATH="${PKG_CONFIG_DIR}" \
  flutter build linux --release )

BUNDLE="${APP_ROOT}/build/linux/x64/release/bundle"

echo "==> 2/5 compute the full shared-library closure"
SEARCH="${FULLROOT}/usr/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu"
# Never bundle: glibc core, and the GPU/driver stack (must match the host GPU
# driver — bundling GLVND/Mesa/drm is a classic AppImage SIGSEGV cause).
DENY="libc.so libm.so libpthread.so libdl.so librt.so ld-linux libresolv.so libnsl.so libutil.so libgcc_s.so libGL.so libEGL.so libGLX.so libGLdispatch.so libOpenGL.so libgbm.so libdrm.so libvulkan.so libglapi.so"
rm -rf "${CLOSURE}" && mkdir -p "${CLOSURE}"
add_lib() { for d in ${SEARCH//:/ }; do
    if [ -e "$d/$1" ]; then cp -L "$d/$1" "${CLOSURE}/$1" 2>/dev/null && return 0; fi
  done; return 1; }
for f in "${BUNDLE}/lib/"*.so*; do cp -L "$f" "${CLOSURE}/" 2>/dev/null; done
for _ in $(seq 1 60); do
  grew=0
  for lib in "${CLOSURE}"/*.so*; do
    while read -r soname; do
      [ -z "${soname}" ] && continue
      base="$(basename "${soname}")"
      [ -e "${CLOSURE}/${base}" ] && continue
      skip=0; for d in ${DENY}; do case "${base}" in ${d}*) skip=1;; esac; done
      [ "${skip}" = 1 ] && continue
      add_lib "${base}" && grew=1
    done < <(LD_LIBRARY_PATH="${CLOSURE}" ldd "${lib}" 2>/dev/null | awk '/=>/ {print $3} /^\//{print $1}' | sort -u)
  done
  [ "${grew}" = 0 ] && break
done
echo "    closure: $(ls "${CLOSURE}" | wc -l) libs"

echo "==> 3/5 assemble AppDir"
rm -rf "${APPDIR}" && mkdir -p "${APPDIR}/usr/bin" "${APPDIR}/usr/lib"
cp -a "${BUNDLE}/." "${APPDIR}/usr/bin/"
cp -a "${CLOSURE}"/*.so* "${APPDIR}/usr/lib/"
# XKB keymap data: AppImage mounts read-only, so xkbcommon needs its own copy
# (otherwise "failed to add default include path /usr/share/X11/xkb").
mkdir -p "${APPDIR}/usr/share/X11"
cp -a /usr/share/X11/xkb "${APPDIR}/usr/share/X11/xkb"
# gdk-pixbuf image loaders + glib schemas (GTK runtime data).
mkdir -p "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders"
cp /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/*.so \
   "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders/" 2>/dev/null || true
mkdir -p "${APPDIR}/usr/share/glib-2.0/schemas"
cp /usr/share/glib-2.0/schemas/gschemas.compiled \
   "${APPDIR}/usr/share/glib-2.0/schemas/" 2>/dev/null || true
# Template the loader cache (AppImage mounts at a random path; the read-only
# mount forbids writing the cache next to the loaders at runtime).
L="${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0"
if [ -f /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders.cache ]; then
  sed "s|/usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders|@APPDIR@/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders|g" \
    /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders.cache > "${L}/loaders.cache.src"
fi

cat > "${APPDIR}/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"

# Bundled GTK/GLib/Pango/Cairo/mpv/ffmpeg + fonts; the GPU stack (libGL/EGL/
# drm/gbm/vulkan) is deliberately left to the host so it matches the driver.
export LD_LIBRARY_PATH="$HERE/usr/lib:$HERE/usr/bin/lib:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="$HERE/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GTK_EXE_PREFIX="$HERE/usr"
export GTK_DATA_PREFIX="$HERE/usr"
export GDK_BACKEND="${GDK_BACKEND:-x11,wayland}"

# xkbcommon: use the BUNDLED keymap data (AppImage mount is read-only).
export XKB_CONFIG_ROOT="$HERE/usr/share/X11/xkb"
export XKB_CONFIG_EXTRA_PATH="$HERE/usr/share/X11/xkb"

# gdk-pixbuf: rewrite the loader cache into a writable temp file (the mount is
# read-only, so writing next to the loaders fails).
export GDK_PIXBUF_MODULEDIR="$HERE/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders"
if [ -f "$HERE/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache.src" ]; then
  _cache="$(mktemp -t gdk-pixbuf-loaders.XXXXXX)"
  sed "s|@APPDIR@|$HERE|g" \
    "$HERE/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache.src" > "$_cache" 2>/dev/null \
    && export GDK_PIXBUF_MODULE_FILE="$_cache"
fi

exec "$HERE/usr/bin/agent_app" "$@"
RUN
chmod +x "${APPDIR}/AppRun"

cat > "${APPDIR}/agent-app.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Agent
Comment=Standalone ABC agent chat client
Exec=agent_app
Icon=agent-app
Categories=Network;InstantMessaging;
Terminal=false
DESK
cp "${APP_ROOT}/web/icons/Icon-192.png" "${APPDIR}/agent-app.png" 2>/dev/null || true

echo "==> 4/5 verify + package AppImage"
LD_LIBRARY_PATH="${APPDIR}/usr/lib:${APPDIR}/usr/bin/lib" \
  ldd "${APPDIR}/usr/bin/agent_app" 2>/dev/null | grep "not found" && {
    echo "ERROR: unresolved libraries" >&2; exit 1; } || true
rm -f "${OUT}"
PATH="${APPIMAGETOOL_BIN}:$PATH" ARCH=x86_64 "${APPIMAGETOOL}" "${APPDIR}" "${OUT}"

echo "==> 5/5 done"
ls -la "${OUT}"
sha256sum "${OUT}"

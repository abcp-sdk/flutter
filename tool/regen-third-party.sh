#!/usr/bin/env bash
# Regenerate the vendored plugin copies in third_party/ from the pub cache.
#
# Why this exists: Flutter has no app-side switch to exclude a plugin from one
# platform's native build. The only place that decides whether a plugin takes
# part in the Android Gradle build is its OWN pubspec.yaml `flutter.plugin.
# platforms` table. `pasteboard` and `desktop_drop` still apply the Kotlin
# Gradle Plugin (KGP) on Android, which Flutter 3.47 warns will fail to build in
# a future release. This app only needs these plugins for desktop + web (real
# clipboard paste / file drag-and-drop UX); Android's native paths are not
# reachable, so the vendored copies simply drop the `android:` platform entry.
#
# Run this after bumping either dependency in pubspec.yaml:
#   tool/regen-third-party.sh
#
# It copies lib/ + pubspec.yaml + LICENSE + README.md from the resolved pub
# cache version, removes the `android:` platform entry, and drops
# `resolution: workspace`. Dart sources stay byte-for-byte upstream.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${DIR}/.." && pwd)"
PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
HOSTED="${PUB_CACHE}/hosted/pub.dev"

for name in pasteboard desktop_drop; do
  # Resolve the version from pubspec.lock (source of truth for what's used).
  version="$(awk -v pkg="  ${name}:" '
    $0 == pkg { in_pkg = 1; next }
    in_pkg && /version:/ { gsub(/[" ]/, "", $2); print $2; exit }
  ' "${APP_ROOT}/pubspec.lock")"
  if [ -z "${version}" ]; then
    echo "error: ${name} not found in pubspec.lock" >&2
    exit 1
  fi

  src="${HOSTED}/${name}-${version}"
  if [ ! -d "${src}" ]; then
    echo "error: ${src} missing — run 'flutter pub get' first" >&2
    exit 1
  fi

  dst="${APP_ROOT}/third_party/${name}"
  echo "==> ${name} ${version} -> third_party/${name}"
  rm -rf "${dst}"
  mkdir -p "${dst}"
  cp -a "${src}/lib" "${dst}/"
  cp -a "${src}/pubspec.yaml" "${dst}/"
  [ -f "${src}/LICENSE" ] && cp -a "${src}/LICENSE" "${dst}/"
  [ -f "${src}/README.md" ] && cp -a "${src}/README.md" "${dst}/"
  # Native sources for every platform we KEEP (everything except android).
  # The `linux/` `windows/` `macos/` `ios/` dirs are required by the respective
  # Gradle/CMake/podspec build when the platform entry stays in the pubspec.
  for plat in linux windows macos ios; do
    [ -d "${src}/${plat}" ] && cp -a "${src}/${plat}" "${dst}/"
  done

  # Strip the android platform entry + workspace resolution from the pubspec,
  # and prepend the provenance note.
  python3 - "${dst}/pubspec.yaml" <<'PY'
import re
import sys

path = sys.argv[1]
text = open(path).read()

# Drop `resolution: workspace` (points at the upstream monorepo).
text = re.sub(r'(?m)^resolution: workspace\n', '', text)

lines = text.splitlines()
out: list[str] = []
i = 0
while i < len(lines):
    line = lines[i]
    # The `android:` entry is a child of `platforms:`; remove it plus its
    # more-indented continuation lines.
    m = re.match(r'^(\s+)android:\s*$', line)
    if m:
        indent = len(m.group(1))
        i += 1
        while i < len(lines):
            nxt = lines[i]
            if nxt.strip() == '':
                i += 1
                continue
            cur_indent = len(nxt) - len(nxt.lstrip())
            if cur_indent <= indent:
                break
            i += 1
        continue
    out.append(line)
    i += 1

note = (
    "# NOTE: vendored copy (see tool/regen-third-party.sh). The `android`\n"
    "# platform entry is intentionally REMOVED so the Android Gradle build does\n"
    "# not pull the KGP-applying module (Flutter 3.47 warns it will break in a\n"
    "# future release). Clipboard paste / drag-and-drop are desktop+web features\n"
    "# here; Dart sources are byte-for-byte upstream.\n"
)
# Insert the note just before the top-level `flutter:` key.
final: list[str] = []
inserted = False
for line in out:
    if not inserted and line.rstrip() == 'flutter:':
        final.append(note.rstrip('\n'))
        inserted = True
    final.append(line)
open(path, 'w').write('\n'.join(final) + '\n')
PY
done

echo
echo "Done. Verify with:"
echo "  flutter pub get"
echo "  grep -c android .flutter-plugins-dependencies  # android list must NOT list pasteboard/desktop_drop"

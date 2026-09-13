#!/usr/bin/env bash
# Build and push the standalone-agent WEB image (nginx serving build/web)
# WITHOUT a local build daemon: buildkitd (in-cluster) -> docker archive ->
# skopeo -> forgejo OCI. Mirrors agent/build-image.sh.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REGISTRY="${REGISTRY:-forgejo.develop.10.199.64.20.nip.io}"
NAMESPACE="${NAMESPACE:-easylab}"
NAME="${NAME:-agent-web}"
TAG="${TAG:-$(date +%Y%m%d%H%M%S)}"
DEST="${REGISTRY}/${NAMESPACE}/${NAME}:${TAG}"
BUILDKIT="${BUILDKIT_ADDR:-tcp://buildkitd.temp.svc.cluster.local:1234}"
FORGEJO_USER="${FORGEJO_USER:-root}"
FORGEJO_PASS="${FORGEJO_PASS:-devpassword}"
DOCKERFILE="Dockerfile.web"

if [ ! -f "${DIR}/build/web/index.html" ]; then
  echo "build/web missing — run 'flutter build web --release' first" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

echo "Building ${NAME} image -> ${DEST} (buildkitd=${BUILDKIT})"
buildctl --addr "${BUILDKIT}" build \
  --frontend dockerfile.v0 \
  --local "context=${DIR}" \
  --local "dockerfile=${DIR}" \
  --opt "filename=${DOCKERFILE}" \
  --opt "build-arg:REGISTRY=${REGISTRY}" \
  --opt "build-arg:HTTP_PROXY=${PROXY:-http://mihomo.develop.svc.cluster.local:7890}" \
  --opt "build-arg:HTTPS_PROXY=${PROXY:-http://mihomo.develop.svc.cluster.local:7890}" \
  --opt "build-arg:NO_PROXY=localhost,127.0.0.1,.svc.cluster.local,.svc,.nip.io,10.199.64.20,develop.10.199.64.20.nip.io" \
  --output "type=docker,name=${NAMESPACE}/${NAME}:${TAG},dest=${WORK}/image.tar" \
  --progress plain

echo "Pushing to forgejo ${DEST}"
skopeo copy \
  --dest-creds "${FORGEJO_USER}:${FORGEJO_PASS}" \
  --dest-tls-verify=false \
  "docker-archive:${WORK}/image.tar:${NAMESPACE}/${NAME}:${TAG}" \
  "docker://${DEST}"

echo "OK ${DEST}"

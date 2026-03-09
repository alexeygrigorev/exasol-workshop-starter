#!/bin/bash
# Installs a pinned version of the Exasol Personal Launcher.
set -euo pipefail

EXASOL_VERSION="1.0.0"
INSTALL_PATH="${HOME}/bin/exasol"
BASE="https://x-up.s3.eu-west-1.amazonaws.com/releases/exasol-personal"

# ── Detect OS ────────────────────────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')   # linux | darwin
ARCH=$(uname -m)                               # x86_64 | aarch64 | arm64

case "${OS}" in
  linux)  OS_LABEL="linux" ;;
  darwin) OS_LABEL="darwin" ;;
  *) echo "❌ Unsupported OS: ${OS}"; exit 1 ;;
esac

# Use raw uname -m value — S3 uses x86_64 not amd64
case "${ARCH}" in
  x86_64)          ARCH_LABEL="x86_64" ;;
  aarch64 | arm64) ARCH_LABEL="arm64" ;;
  *) echo "❌ Unsupported arch: ${ARCH}"; exit 1 ;;
esac

DOWNLOAD_URL="${BASE}/${OS_LABEL}/${ARCH_LABEL}/${EXASOL_VERSION}/exasol"

echo "================================================"
echo "OS:      ${OS_LABEL}"
echo "Arch:    ${ARCH_LABEL}"
echo "Version: ${EXASOL_VERSION}"
echo "URL:     ${DOWNLOAD_URL}"
echo "Target:  ${INSTALL_PATH}"
echo "================================================"

# ── Skip if already correct version ─────────────────────────────────────────
if [ -f "${INSTALL_PATH}" ]; then
  INSTALLED=$("${INSTALL_PATH}" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
  if [ "${INSTALLED}" = "${EXASOL_VERSION}" ]; then
    echo "✅ Exasol Launcher ${EXASOL_VERSION} already installed — skipping"
    exit 0
  fi
  echo "⚠️  Found version ${INSTALLED}, replacing with ${EXASOL_VERSION}"
fi

# ── Download ─────────────────────────────────────────────────────────────────
mkdir -p "${HOME}/bin"
curl -fSL --retry 3 "${DOWNLOAD_URL}" -o "${INSTALL_PATH}" \
  || { echo "❌ Download failed: ${DOWNLOAD_URL}"; exit 1; }

chmod +x "${INSTALL_PATH}"

# ── Ensure ~/bin is on PATH ───────────────────────────────────────────────────
grep -q '"${HOME}/bin"' ~/.bashrc 2>/dev/null \
  || echo 'export PATH="${HOME}/bin:${PATH}"' >> ~/.bashrc
export PATH="${HOME}/bin:${PATH}"

# ── Verify ───────────────────────────────────────────────────────────────────
INSTALLED=$("${INSTALL_PATH}" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
if [ "${INSTALLED}" = "${EXASOL_VERSION}" ]; then
  echo "✅ Exasol Launcher ${EXASOL_VERSION} ready at ${INSTALL_PATH}"
else
  echo "❌ Version mismatch — got '${INSTALLED}', expected '${EXASOL_VERSION}'"
  exit 1
fi

#!/bin/bash
# Installs a pinned version of the Exasol Personal Launcher.
# OS/arch neutral: detects platform at runtime.
set -euo pipefail

EXASOL_VERSION="1.0.0"
INSTALL_DIR="${HOME}/bin"
INSTALL_PATH="${INSTALL_DIR}/exasol"

# ── Detect OS ────────────────────────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')   # linux | darwin
ARCH=$(uname -m)                               # x86_64 | aarch64 | arm64

case "${OS}" in
  linux)  OS_LABEL="linux" ;;
  darwin) OS_LABEL="darwin" ;;
  *)      echo "❌ Unsupported OS: ${OS}"; exit 1 ;;
esac

case "${ARCH}" in
  x86_64)          ARCH_LABEL="amd64" ;;
  aarch64 | arm64) ARCH_LABEL="arm64" ;;
  *)               echo "❌ Unsupported arch: ${ARCH}"; exit 1 ;;
esac

BINARY="exasol-${OS_LABEL}-${ARCH_LABEL}"
BASE_URL="https://downloads.exasol.com/exasol-personal"

# Try versioned URL first, fall back to latest
VERSIONED_URL="${BASE_URL}/${EXASOL_VERSION}/${BINARY}"
LATEST_URL="${BASE_URL}/${BINARY}"

echo "================================================"
echo "OS:      ${OS_LABEL}"
echo "Arch:    ${ARCH_LABEL}"
echo "Version: ${EXASOL_VERSION}"
echo "Target:  ${INSTALL_PATH}"
echo "================================================"

# ── Skip if already installed at correct version ─────────────────────────────
if command -v exasol &>/dev/null; then
  INSTALLED=$(exasol version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
  if [ "${INSTALLED}" = "${EXASOL_VERSION}" ]; then
    echo "✅ Exasol Launcher ${EXASOL_VERSION} already installed — skipping"
    exit 0
  fi
  echo "⚠️  Found version ${INSTALLED}, replacing with ${EXASOL_VERSION}"
fi

# ── Download ─────────────────────────────────────────────────────────────────
mkdir -p "${INSTALL_DIR}"

echo "Trying versioned URL: ${VERSIONED_URL}"
if curl -fsSL --retry 3 "${VERSIONED_URL}" -o "${INSTALL_PATH}" 2>/dev/null; then
  echo "✅ Downloaded from versioned URL"
else
  echo "⚠️  Versioned URL failed — falling back to latest"
  echo "Trying: ${LATEST_URL}"
  curl -fsSL --retry 3 "${LATEST_URL}" -o "${INSTALL_PATH}" \
    || { echo "❌ Both download URLs failed"; exit 1; }
  echo "✅ Downloaded from latest URL"
fi

chmod +x "${INSTALL_PATH}"

# ── Ensure ~/bin is on PATH ───────────────────────────────────────────────────
if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
  export PATH="${INSTALL_DIR}:${PATH}"
  echo "export PATH=\"${INSTALL_DIR}:\${PATH}\"" >> ~/.bashrc
fi

# ── Verify ───────────────────────────────────────────────────────────────────
INSTALLED=$(exasol version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
echo "Installed version: ${INSTALLED}"

if [ "${INSTALLED}" = "${EXASOL_VERSION}" ]; then
  echo "✅ Exasol Launcher ${EXASOL_VERSION} ready at ${INSTALL_PATH}"
else
  echo "⚠️  Version mismatch (got ${INSTALLED}, wanted ${EXASOL_VERSION})"
  echo "   Continuing anyway — check if 1.0.0 download URL exists on server"
fi

#!/usr/bin/env bash
# Idempotent Cloud Agent setup for Tint Drop (Godot 4.7 + Python tools).
set -euo pipefail

GODOT_VERSION="4.7-stable"
GODOT_ASSET="Godot_v${GODOT_VERSION}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ASSET}.zip"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

install_godot() {
  local dest="$1"
  local tmp
  tmp="$(mktemp -d)"
  echo "Downloading Godot ${GODOT_VERSION}..."
  curl -fsSL -o "${tmp}/godot.zip" "${GODOT_URL}"
  unzip -o -q "${tmp}/godot.zip" -d "${tmp}"
  chmod +x "${tmp}/${GODOT_ASSET}"
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo install -m 0755 "${tmp}/${GODOT_ASSET}" "${dest}"
  else
    install -m 0755 "${tmp}/${GODOT_ASSET}" "${dest}"
  fi
  rm -rf "${tmp}"
}

# Resolve where the `godot` binary should live (prefer a PATH dir we can write).
GODOT_BIN=""
if command -v godot >/dev/null 2>&1 && godot --version 2>/dev/null | grep -q "^4\.7\.stable"; then
  GODOT_BIN="$(command -v godot)"
  echo "Godot 4.7 already installed at ${GODOT_BIN}"
else
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    GODOT_BIN="/usr/local/bin/godot"
  else
    mkdir -p "${HOME}/.local/bin"
    GODOT_BIN="${HOME}/.local/bin/godot"
    case ":${PATH}:" in
      *":${HOME}/.local/bin:"*) : ;;
      *) echo "NOTE: add ${HOME}/.local/bin to PATH to run 'godot' directly." ;;
    esac
  fi
  install_godot "${GODOT_BIN}"
fi

"${GODOT_BIN}" --version

# Pre-import assets so the editor / headless runs start clean (idempotent).
echo "Importing Godot project (headless)..."
( cd "${REPO_DIR}/godot" && timeout 600 "${GODOT_BIN}" --headless --import )

echo "Tint Drop environment ready."

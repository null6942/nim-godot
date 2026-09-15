#!/usr/bin/env bash
# Cloud Agent install: provision Godot 4.4.1 (headless-capable) + export templates,
# then import the project so the editor/runtime and Web export work out of the box.
# Idempotent: safe to re-run; skips downloads when the right version is already present.
set -euo pipefail

GODOT_VERSION="4.4.1-stable"
GODOT_DOTTED="4.4.1.stable"
GODOT_BIN="/usr/local/bin/godot"
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}"
EDITOR_ZIP="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
EDITOR_EXE="Godot_v${GODOT_VERSION}_linux.x86_64"
TEMPLATES_TPZ="Godot_v${GODOT_VERSION}_export_templates.tpz"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_DOTTED}"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing system libraries Godot needs (GL, X11, audio, Xvfb)"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
  libgl1 libglu1-mesa libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libxext6 libxrender1 libfontconfig1 libasound2t64 libpulse0 libudev1 \
  xvfb ca-certificates unzip curl >/dev/null

echo "==> Ensuring Godot ${GODOT_VERSION} binary"
if [ -x "${GODOT_BIN}" ] && "${GODOT_BIN}" --version 2>/dev/null | grep -q "${GODOT_DOTTED}"; then
  echo "    Godot ${GODOT_DOTTED} already installed"
else
  tmp="$(mktemp -d)"
  curl -fsSL -o "${tmp}/${EDITOR_ZIP}" "${BASE_URL}/${EDITOR_ZIP}"
  unzip -o -q "${tmp}/${EDITOR_ZIP}" -d "${tmp}"
  sudo install -m 755 "${tmp}/${EDITOR_EXE}" "${GODOT_BIN}"
  rm -rf "${tmp}"
  echo "    Installed $(${GODOT_BIN} --version)"
fi

echo "==> Ensuring Godot ${GODOT_VERSION} export templates"
if [ -f "${TEMPLATE_DIR}/version.txt" ] && grep -q "${GODOT_DOTTED}" "${TEMPLATE_DIR}/version.txt" \
   && [ -f "${TEMPLATE_DIR}/web_release.zip" ]; then
  echo "    Export templates already installed"
else
  tmp="$(mktemp -d)"
  curl -fsSL -o "${tmp}/${TEMPLATES_TPZ}" "${BASE_URL}/${TEMPLATES_TPZ}"
  unzip -o -q "${tmp}/${TEMPLATES_TPZ}" -d "${tmp}"
  mkdir -p "${TEMPLATE_DIR}"
  cp -f "${tmp}"/templates/* "${TEMPLATE_DIR}/"
  rm -rf "${tmp}"
  echo "    Installed export templates $(cat "${TEMPLATE_DIR}/version.txt")"
fi

echo "==> Importing project assets (headless)"
xvfb-run -a "${GODOT_BIN}" --headless --path "${REPO_ROOT}" --import >/dev/null 2>&1 || true

echo "==> Godot environment ready"

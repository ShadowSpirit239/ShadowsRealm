#!/usr/bin/env bash
# ShadowsRealm — bootstrap.
#
# Clones (or updates) the ShadowsRealm repo into ~/.local/share/ShadowsRealm,
# then runs the full installer from there.
#
# One-liner:
#   bash <(curl -fsSL https://raw.githubusercontent.com/ShadowSpirit239/ShadowsRealm/main/bootstrap.sh)
#
# Any extra arguments are forwarded to install.sh, e.g.:
#   bash <(curl -fsSL .../bootstrap.sh) --yes --no-sddm
set -euo pipefail

REPO_URL="${SHADOWSREALM_REPO:-https://github.com/ShadowSpirit239/ShadowsRealm.git}"
DEST="${SHADOWSREALM_DIR:-$HOME/.local/share/ShadowsRealm}"
BRANCH="${SHADOWSREALM_BRANCH:-main}"

c_cyan=$'\e[36m'; c_green=$'\e[32m'; c_red=$'\e[31m'; c_rst=$'\e[0m'
info() { printf '%s::%s %s\n' "$c_cyan" "$c_rst" "$*"; }
ok()   { printf '%sok%s %s\n' "$c_green" "$c_rst" "$*"; }
die()  { printf '%sxx%s %s\n' "$c_red" "$c_rst" "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Do not run as root. Run as your normal user; sudo is used where needed."
command -v git >/dev/null 2>&1 || die "git is required. Install it first (e.g. 'sudo pacman -S git')."

# ---- clone or update ----
if [[ -d "$DEST/.git" ]]; then
    info "Updating existing checkout at $DEST"
    git -C "$DEST" fetch --depth 1 origin "$BRANCH"
    git -C "$DEST" checkout "$BRANCH"
    git -C "$DEST" reset --hard "origin/$BRANCH"
elif [[ -e "$DEST" ]]; then
    die "$DEST exists but is not a git repo. Move or remove it, then re-run."
else
    info "Cloning $REPO_URL -> $DEST"
    mkdir -p "$(dirname "$DEST")"
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$DEST"
fi
ok "Repo ready at $DEST"

# ---- run the installer from the repo dir ----
cd "$DEST"
chmod +x install.sh 2>/dev/null || true
info "Running install.sh"
exec ./install.sh "$@"

#!/usr/bin/env bash
# ShadowsRealm — full installer (Arch Linux / Arch-based).
#
# This is the end-to-end installer:
#   1. Installs an AUR helper (yay) if missing.
#   2. Installs all dependencies (Caelestia shell + CLI, Quickshell, Hyprland,
#      the AI sidebar / cheat-sheet runtime, SDDM, fonts, utilities).
#   3. Deploys the ShadowsRealm config + SDDM theme by invoking ./install.fish.
#
# For config-only deployment (no package installs), run ./install.fish directly.
#
# Usage:
#   ./install.sh                 # interactive full install
#   ./install.sh --yes           # non-interactive (assume yes)
#   ./install.sh --no-sddm       # skip the SDDM theme + (sudo) steps
#   ./install.sh --no-deps       # skip dependency install, just deploy configs
#   ./install.sh --no-apps       # install core deps but skip the bundled apps
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=false
DO_SDDM=true
DO_DEPS=true
DO_APPS=true

for arg in "$@"; do
    case "$arg" in
        --yes|-y) ASSUME_YES=true ;;
        --no-sddm) DO_SDDM=false ;;
        --no-deps) DO_DEPS=false ;;
        --no-apps) DO_APPS=false ;;
        -h|--help)
            sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# ---- pretty output ----
c_cyan=$'\e[36m'; c_green=$'\e[32m'; c_yellow=$'\e[33m'; c_red=$'\e[31m'; c_rst=$'\e[0m'
info() { printf '%s::%s %s\n' "$c_cyan" "$c_rst" "$*"; }
ok()   { printf '%sok%s %s\n' "$c_green" "$c_rst" "$*"; }
warn() { printf '%s!!%s %s\n' "$c_yellow" "$c_rst" "$*"; }
die()  { printf '%sxx%s %s\n' "$c_red" "$c_rst" "$*" >&2; exit 1; }

confirm() {
    $ASSUME_YES && return 0
    read -rp "$* [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# ---- sanity checks ----
[[ $EUID -eq 0 ]] && die "Do not run as root. Run as your normal user; sudo is used where needed."

if ! command -v pacman >/dev/null 2>&1; then
    warn "This full installer targets Arch Linux (pacman not found)."
    warn "On other distros, install the dependencies listed in README.md manually,"
    warn "then run ./install.fish to deploy the config."
    if confirm "Continue and just deploy the config files (no package install)?"; then
        DO_DEPS=false
    else
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 1. Dependencies
# ---------------------------------------------------------------------------
install_deps() {
    info "Synchronising package databases"
    sudo pacman -Syu --needed --noconfirm base-devel git

    # --- AUR helper ---
    if ! command -v yay >/dev/null 2>&1; then
        info "Installing yay (AUR helper)"
        tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        ( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
        rm -rf "$tmp"
    fi
    ok "AUR helper present"

    # --- official-repo packages ---
    local repo_pkgs=(
        # Compositor + portals
        hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        hyprpicker hypridle hyprlock
        # Display manager + theme stack
        sddm qt6-base qt6-declarative qt6-svg qt6-quicktimeline qt6-5compat
        qt6-imageformats
        # Caelestia shell build/runtime deps
        cmake ninja libqalculate pipewire wireplumber aubio
        cli11 fftw libcava
        # Auth / keyring / location / bluetooth (referenced by execs.conf)
        polkit-gnome gnome-keyring gammastep geoclue bluez bluez-utils
        # Wayland utilities used by the configs/keybinds
        wl-clipboard cliphist inotify-tools brightnessctl ddcutil
        trash-cli foot fish eza fastfetch starship btop jq curl
        ydotool grim slurp wf-recorder
        # Fonts / icons / theme
        adw-gtk-theme papirus-icon-theme ttf-jetbrains-mono-nerd
        noto-fonts noto-fonts-emoji
    )
    info "Installing official-repo packages"
    sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}" || warn "Some repo packages failed; review the output above."

    # --- applications (the default apps the config points at, plus a sensible
    #     Hyprland app suite). Skip with --no-apps. ---
    if $DO_APPS; then
        local repo_apps=(
            # Default apps referenced in config/hypr/variables.conf + keybinds
            thunar thunar-archive-plugin thunar-volman tumbler gvfs   # file manager ($fileExplorer) + thumbnails/mounting
            nemo                                                      # alt file manager (Super+Alt+E)
            pavucontrol                                               # audio control (Ctrl+Alt+V)
            qps                                                       # process viewer (Ctrl+Alt+Escape)
            # Archive manager
            ark unzip p7zip unrar
            # Office
            libreoffice-fresh
            # Media
            mpv loupe imv zathura zathura-pdf-mupdf
            # Misc desktop apps
            gnome-calculator
        )
        info "Installing applications (use --no-apps to skip)"
        sudo pacman -S --needed --noconfirm "${repo_apps[@]}" || warn "Some apps failed; review the output above."
    fi

    # --- AUR packages ---
    local aur_pkgs=(
        quickshell                 # the Quickshell runtime (both shells)
        caelestia-cli              # the `caelestia` command used by keybinds/execs
        caelestia-shell            # installs the Caelestia.Config QML plugin + base shell
        app2unit                   # `app2unit --` app launcher used in keybinds
    )
    info "Installing AUR packages (this can take a while; builds from source)"
    yay -S --needed --noconfirm "${aur_pkgs[@]}" || warn "Some AUR packages failed; you may need to install them manually."

    # --- AUR applications (the default browser/editor + extras). Skip with --no-apps. ---
    if $DO_APPS; then
        local aur_apps=(
            zen-browser-bin            # default $browser (Super+W)
            vscodium-bin               # default $editor / codium (Super+C)
            webcord                    # Discord client (Wayland-friendly)
        )
        info "Installing AUR applications (use --no-apps to skip)"
        yay -S --needed --noconfirm "${aur_apps[@]}" || warn "Some AUR apps failed; install them manually if needed."
    fi

    ok "Dependencies installed"
    warn "Optional for full end-4 fidelity (LaTeX in AI replies, emoji search, etc.):"
    warn "  yay -S illogical-impulse-microtex-git matugen-bin"
}

if $DO_DEPS; then
    if confirm "Install ShadowsRealm dependencies via pacman + yay?"; then
        install_deps
    else
        warn "Skipping dependency install."
    fi
else
    info "Skipping dependency install (--no-deps or unsupported distro)"
fi

# ---------------------------------------------------------------------------
# 2. Build the bundled Caelestia plugin (fallback if AUR caelestia-shell is unavailable)
# ---------------------------------------------------------------------------
# The AUR `caelestia-shell` package installs the Caelestia.Config QML plugin.
# If you prefer to build the bundled copy instead, uncomment the block below.
#
# build_plugin() {
#     info "Building bundled Caelestia plugin"
#     local src="$REPO_DIR/config/quickshell/caelestia"
#     cmake -S "$src" -B "$src/build" -G Ninja \
#         -DCMAKE_BUILD_TYPE=Release -DINSTALL_QMLDIR=/usr/lib/qt6/qml \
#         -DVERSION=1.0.0 -DGIT_REVISION=shadowsrealm
#     cmake --build "$src/build"
#     sudo cmake --install "$src/build"
# }
# build_plugin

if ! pacman -Qq caelestia-shell >/dev/null 2>&1 && ! ls /usr/lib/qt6/qml/Caelestia 2>/dev/null; then
    warn "The Caelestia.Config QML plugin doesn't appear to be installed."
    warn "Install it via 'yay -S caelestia-shell', or build the bundled copy"
    warn "(see the commented build_plugin() block in install.sh)."
fi

# ---------------------------------------------------------------------------
# 3. Deploy config + SDDM theme (delegates to install.fish)
# ---------------------------------------------------------------------------
if ! command -v fish >/dev/null 2>&1; then
    die "fish is required to deploy the config but isn't installed. Re-run without --no-deps, or 'sudo pacman -S fish'."
fi

info "Deploying ShadowsRealm config files"
fish_args=()
$DO_SDDM || fish_args+=("--no-sddm")
fish "$REPO_DIR/install.fish" "${fish_args[@]}"

# ---------------------------------------------------------------------------
# 4. Enable SDDM
# ---------------------------------------------------------------------------
if $DO_SDDM && command -v systemctl >/dev/null 2>&1; then
    if confirm "Enable the SDDM display manager service?"; then
        sudo systemctl enable sddm.service || warn "Could not enable sddm.service"
    fi
fi

echo
ok "ShadowsRealm full install complete."
info "Log out (or reboot) and pick your Hyprland session at the SDDM login screen."
info "On first launch you'll be greeted and the cheat sheet opens automatically."
info "AI sidebar: Super+A   |   Cheat sheet: Super+/"
info "Set up Cursor in the AI sidebar:  /model cursor-default  then  /key <your-key>"

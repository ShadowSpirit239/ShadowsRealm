#!/usr/bin/env fish
# ShadowsRealm installer.
# Deploys the merged Caelestia + end-4 Hyprland configuration, the AI sidebar
# (with Cursor support), the keybind cheat sheet, and the matching SDDM theme.
#
# Usage:
#   ./install.fish              # full install
#   ./install.fish --no-sddm    # skip the (sudo) SDDM theme steps

set -l repo_dir (status dirname)
set -l config_src "$repo_dir/config"
set -l do_sddm true

for arg in $argv
    switch $arg
        case --no-sddm
            set do_sddm false
        case '*'
            echo "Unknown option: $arg"; exit 1
    end
end

function info;  set_color cyan;   echo "::"  $argv; set_color normal; end
function ok;    set_color green;  echo "ok"  $argv; set_color normal; end
function warn;  set_color yellow; echo "!!"  $argv; set_color normal; end

set -l stamp (date +%Y%m%d-%H%M%S)
set -l backup_dir "$HOME/.config/shadowsrealm-backup-$stamp"

# ---- 1. Back up existing config ----
info "Backing up existing config to $backup_dir"
mkdir -p "$backup_dir"
for d in hypr quickshell/caelestia quickshell/ii
    if test -e "$HOME/.config/$d"
        mkdir -p "$backup_dir/"(dirname $d)
        cp -R "$HOME/.config/$d" "$backup_dir/$d"
        ok "backed up ~/.config/$d"
    end
end

# ---- 2. Deploy configs ----
info "Installing Hyprland config -> ~/.config/hypr"
mkdir -p "$HOME/.config/hypr"
cp -R "$config_src/hypr/." "$HOME/.config/hypr/"

info "Installing Caelestia shell -> ~/.config/quickshell/caelestia"
mkdir -p "$HOME/.config/quickshell/caelestia"
cp -R "$config_src/quickshell/caelestia/." "$HOME/.config/quickshell/caelestia/"

info "Installing AI sidebar / cheat sheet shell -> ~/.config/quickshell/ii"
mkdir -p "$HOME/.config/quickshell/ii"
cp -R "$config_src/quickshell/ii/." "$HOME/.config/quickshell/ii/"

# Utility scripts (emoji picker, snip-to-search, etc.)
info "Installing utility scripts -> ~/.config/hypr/hyprland/scripts"
mkdir -p "$HOME/.config/hypr/hyprland/scripts"
cp -R "$repo_dir/scripts/." "$HOME/.config/hypr/hyprland/scripts/"
chmod +x "$HOME/.config/hypr/hyprland/scripts/"*.sh 2>/dev/null

# ---- 3. First-run marker: ensure the welcome + cheat sheet fire on first launch ----
info "Resetting first-run marker so the welcome + cheat sheet auto-open"
for f in (find "$HOME/.local/state" -name first_run.txt 2>/dev/null)
    rm -f "$f"
end

# ---- 4. SDDM theme (needs sudo) ----
if test "$do_sddm" = true
    if type -q sudo
        info "Installing SDDM theme 'shadowsrealm' (requires sudo)"
        sudo mkdir -p /usr/share/sddm/themes
        sudo cp -R "$repo_dir/sddm/shadowsrealm" /usr/share/sddm/themes/

        # Optionally seed the login wallpaper from the Caelestia default.
        set -l wp "$config_src/quickshell/caelestia/assets/wallpaper.webp"
        if test -f "$wp"
            sudo cp "$wp" /usr/share/sddm/themes/shadowsrealm/assets/wallpaper.png 2>/dev/null; or true
        end

        info "Activating theme via /etc/sddm.conf.d/shadowsrealm.conf"
        sudo mkdir -p /etc/sddm.conf.d
        sudo cp "$repo_dir/sddm/sddm.conf.d/shadowsrealm.conf" /etc/sddm.conf.d/

        info "Installing the color-sync helper + scoped sudoers rule"
        sudo install -m 0755 "$repo_dir/scripts/shadowsrealm-sddm-sync" /usr/local/bin/shadowsrealm-sddm-sync
        sudo install -m 0440 "$repo_dir/sddm/sudoers.d/shadowsrealm-sddm-sync" /etc/sudoers.d/shadowsrealm-sddm-sync

        info "Generating initial SDDM palette from the active scheme"
        sudo /usr/local/bin/shadowsrealm-sddm-sync; or warn "scheme not generated yet; will sync on first scheme change"

        info "Enabling the user path unit that keeps the greeter in sync"
        mkdir -p "$HOME/.config/systemd/user"
        cp "$repo_dir/systemd/user/shadowsrealm-sddm-sync.path" "$HOME/.config/systemd/user/"
        cp "$repo_dir/systemd/user/shadowsrealm-sddm-sync.service" "$HOME/.config/systemd/user/"
        systemctl --user daemon-reload
        systemctl --user enable --now shadowsrealm-sddm-sync.path; or warn "could not enable user path unit"
        ok "SDDM theme installed"
    else
        warn "sudo not found; skipping SDDM theme. Re-run on a machine with sudo or use --no-sddm."
    end
else
    info "Skipping SDDM theme (--no-sddm)"
end

# ---- 5. Done ----
ok "ShadowsRealm installed."
info "Next steps:"
echo "  1. Build/install the Caelestia Quickshell plugin (see config/quickshell/caelestia/README.md)."
echo "  2. Install deps: quickshell hyprland app2unit fuzzel cliphist ydotool curl sddm + fonts."
echo "  3. Reload Hyprland (or log out/in). On first launch the cheat sheet opens automatically."
echo "  4. AI sidebar: Super+A   |   Cheat sheet: Super+/"
echo "  5. In the AI sidebar, run '/model cursor-default' then '/key <your-cursor-key>'."
echo ""
warn "Backup of your previous config is at: $backup_dir"

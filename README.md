# ShadowsRealm

A unified Hyprland desktop that merges the **Caelestia** shell + dotfiles with
**end-4/dots-hyprland**, under a single ShadowsRealm identity.

- **Caelestia** owns the visible shell: bar, launcher, dashboard, notifications,
  OSD, session, lock and wallpaper.
- **end-4 (`ii`)** is run in a stripped-down mode that contributes only its
  **AI sidebar** and **keybind cheat sheet**.
- The AI sidebar gains full **Cursor API** support alongside the existing
  Gemini / OpenAI / Mistral / Ollama providers.
- A matching **SDDM login theme** tracks the desktop's Material You colors.

> Note: this is a Linux/Hyprland/Wayland configuration. It cannot run on macOS;
> deploy and test it on your Hyprland machine.

## Architecture

```
~/.config/
├── hypr/                      # Hyprland config (Caelestia base, merged)
└── quickshell/
    ├── caelestia/             # Primary shell (bar, launcher, panels, lock, ...)
    └── ii/                    # Minimal: AI sidebar + cheat sheet only
```

Both are Quickshell configs, but only one full shell draws panels. `ii` runs the
custom **`shadowsrealm` panel family** (`config/quickshell/ii/panelFamilies/ShadowsRealmFamily.qml`)
which loads only `SidebarLeft` (AI) and `Cheatsheet` — no competing bar, dock,
overview, wallpaper or lock. Both shells are launched from
`config/hypr/hyprland/execs.conf`:

```
exec-once = caelestia shell -d   # Caelestia: the desktop
exec-once = qs -c ii             # ShadowsRealm: AI sidebar + cheat sheet
```

## Keybinds

The cheat sheet is the source of truth — open it any time with **`Super + /`**.
Keybinds in `config/hypr/hyprland/keybinds.conf` use Hyprland's `bindd`
(description) form with `Category: Description` labels, so `hyprctl binds -j`
feeds the cheat sheet automatically. Highlights:

| Keybind             | Action                                       |
|---------------------|----------------------------------------------|
| `Super + /`         | Toggle the keybind cheat sheet               |
| `Super + A`         | Toggle the AI sidebar                        |
| `Super` (tap)       | Launcher                                     |
| `Super + Q`         | Close window                                 |
| `Super + T/W/C/E`   | Terminal / Browser / Editor / Files          |
| `Super+Shift + D`   | Discord (WebCord)                            |
| `Super+Shift + O`   | LibreOffice                                  |
| `Super+Shift + P/I/V` | PDF / Image / Media viewer                 |
| `Super+Shift + A/K` | Archive manager / Calculator                 |
| `Super + J / O`     | Toggle split direction / pseudotile          |
| `Super+Ctrl + ,/.`  | Focus previous / next monitor                |

## AI sidebar + Cursor API

The AI sidebar (`Super + A`) supports Gemini, OpenAI, Mistral, Ollama, and
**Cursor**. Cursor is wired in exactly like the others:

- Provider strategy: `config/quickshell/ii/services/ai/CursorApiStrategy.qml`
  (OpenAI-compatible streaming).
- Registered in `config/quickshell/ii/services/Ai.qml` (`apiStrategies`, `tools`,
  and a `cursor-default` model with `key_id: "cursor"`).
- Configurable endpoint: `ai.cursorEndpoint` in
  `config/quickshell/ii/modules/common/Config.qml` (default
  `https://api.cursor.sh/v1/chat/completions`). Repoint it at your Cursor
  backend or an OpenAI-compatible proxy without touching code.

Set it up from inside the sidebar (identical flow to Gemini/OpenAI):

```
/model cursor-default
/key <your-cursor-api-key>
```

Keys are stored per provider (`apiKeys.cursor`), so adding Cursor never touches
your existing Gemini/OpenAI keys.

## SDDM login theme

A custom QML theme at `sddm/shadowsrealm/` mirrors the Caelestia lock screen
(blurred wallpaper, centered clock, rounded Material You password field).

Its palette (`Colors.qml`) is generated from the active scheme by
`scripts/shadowsrealm-sddm-sync` and kept in sync **live**: a user systemd path
unit (`systemd/user/shadowsrealm-sddm-sync.path`) watches the scheme files and
regenerates the colors whenever your wallpaper/scheme changes.

Because the theme dir is root-owned, the sync helper is installed root-owned and
granted a single, narrowly-scoped `NOPASSWD` sudoers rule
(`sddm/sudoers.d/shadowsrealm-sddm-sync`). **Security note:** this lets your
session run that one helper as root without a password. If you prefer not to
grant that, install with `--no-sddm` and run `shadowsrealm-sddm-sync` manually
when you want to refresh the login colors.

## Troubleshooting

### SDDM shows a black screen

The greeter is Qt6. The theme avoids Qt5-only modules (`QtGraphicalEffects`,
`SddmComponents`) for this reason — if you saw a black screen on an older
version, update to the latest theme:

```bash
sudo cp -r sddm/shadowsrealm /usr/share/sddm/themes/
```

Then test the theme directly (shows QML errors in the terminal if any):

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/shadowsrealm
# (older SDDM: sddm-greeter --test-mode --theme /usr/share/sddm/themes/shadowsrealm)
```

Checklist:
- Packages: `sudo pacman -S --needed sddm qt6-declarative qt6-svg qt6-5compat qt6-imageformats`
- Theme is selected: `/etc/sddm.conf.d/shadowsrealm.conf` contains `[Theme]` / `Current=shadowsrealm`
- Service is enabled: `sudo systemctl enable sddm` (disable any other DM first, e.g. `sudo systemctl disable gdm lightdm`)
- A near-black background **with** a clock and login card is the intended dark theme. A solid background with no clock/card means a QML load error — run the test-mode command above and check the output.

### SDDM wasn't installed

`install.fish` only deploys config files. Use `./install.sh` (the full
installer) to install + enable SDDM, or do it manually:

```bash
sudo pacman -S --needed sddm
sudo systemctl enable sddm
```

## Install

### One-line bootstrap (Arch / Arch-based) — easiest

Clones the repo into `~/.local/share/ShadowsRealm` and runs the full installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ShadowSpirit239/ShadowsRealm/main/bootstrap.sh)
```

Extra args are forwarded to `install.sh` (e.g. `... bootstrap.sh) --yes --no-sddm`).
Re-running updates the checkout and reinstalls.

### Full install (Arch / Arch-based) — recommended

`install.sh` does everything: installs an AUR helper, all dependencies
(Caelestia shell + CLI, Quickshell, Hyprland, the AI/cheat-sheet runtime, SDDM,
fonts, utilities), then deploys the config and SDDM theme.

```bash
./install.sh                # interactive full install
./install.sh --yes          # non-interactive (assume yes)
./install.sh --no-sddm      # skip the SDDM theme + sudo steps
./install.sh --no-deps      # skip package installs, just deploy configs
./install.sh --no-apps      # install core deps but skip the bundled apps
```

#### Bundled applications

Beyond the shell/compositor deps, `install.sh` also installs a default app
suite (skip with `--no-apps`):

| Role          | App(s) |
|---------------|--------|
| Terminal      | `foot` |
| File manager  | `thunar` (+ archive/volman/thumbnails), `nemo` |
| Browser       | `zen-browser` |
| Editor        | `vscodium` (`codium`) |
| Archive       | `ark` (+ `unzip`, `p7zip`, `unrar`) |
| Office        | `libreoffice-fresh` |
| Chat          | `webcord` |
| Media         | `mpv`, `imv`/`loupe` (images), `zathura` (PDF) |
| Audio/system  | `pavucontrol`, `qps`, `gnome-calculator` |

The terminal/browser/editor/file-manager defaults are wired into
`config/hypr/variables.conf` — change those variables if you prefer different
apps.

### Config-only deploy (any distro)

If you already have the dependencies, `install.fish` just deploys the files
(with a backup) and the SDDM theme:

```fish
./install.fish            # deploy config + SDDM theme
./install.fish --no-sddm  # skip the SDDM (sudo) steps
```

On other distros, install the equivalents of the packages listed in
`install.sh` (Quickshell, Hyprland, `caelestia-cli`/`caelestia-shell`,
`app2unit`, `cliphist`, `ydotool`, `curl`, `sddm`, fonts), then run
`./install.fish`.

After installing:

1. Reload Hyprland (or log out and back in; pick the Hyprland session at SDDM).
   On first launch you'll be greeted and the **cheat sheet opens automatically**.
2. `Super + A` for the AI sidebar, `Super + /` for the cheat sheet.
3. Set up Cursor in the AI sidebar: `/model cursor-default` then `/key <key>`.

Your previous config is backed up to `~/.config/shadowsrealm-backup-<timestamp>`.

## Credits

- [Caelestia shell + dots](https://github.com/caelestia-dots)
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

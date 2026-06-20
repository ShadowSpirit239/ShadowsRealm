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

| Keybind        | Action                                            |
|----------------|---------------------------------------------------|
| `Super + /`    | Toggle the keybind cheat sheet                    |
| `Super + A`    | Toggle the AI sidebar                             |
| `Super` (tap)  | Launcher                                          |
| `Super + Q`    | Close window                                      |

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

## Install

### Full install (Arch / Arch-based) — recommended

`install.sh` does everything: installs an AUR helper, all dependencies
(Caelestia shell + CLI, Quickshell, Hyprland, the AI/cheat-sheet runtime, SDDM,
fonts, utilities), then deploys the config and SDDM theme.

```bash
./install.sh                # interactive full install
./install.sh --yes          # non-interactive (assume yes)
./install.sh --no-sddm      # skip the SDDM theme + sudo steps
./install.sh --no-deps      # skip package installs, just deploy configs
```

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

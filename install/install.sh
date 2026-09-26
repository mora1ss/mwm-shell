#!/usr/bin/env bash
# mwm-shell installer. One command clones, installs packages, and wires Hyprland.

set -euo pipefail

REPO_URL="https://github.com/mora1ss/mwm-shell.git"
REPO_BRANCH="main"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mwm-shell"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
QS_DIR="$CONFIG_HOME/quickshell"
QS_LINK="$QS_DIR/mwm"
MW_DIR="$CONFIG_HOME/mwm"
MARKER="mwm-shell:managed"

pacman_pkgs=(
    hyprland
    kitty
    qt6-base
    qt6-declarative
    qt6-5compat
    qt6-wayland
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    pipewire
    wireplumber
    playerctl
    networkmanager
    bluez
    bluez-utils
    brightnessctl
    inotify-tools
    power-profiles-daemon
    lm_sensors
    fontconfig
    ttf-ibm-plex
    noto-fonts
    git
)

say() { printf '%s\n' "$*"; }
die() { printf 'mwm: %s\n' "$*" >&2; exit 1; }

need_arch() {
    if ! command -v pacman >/dev/null 2>&1; then
        die "este instalador cobre Arch Linux e CachyOS."
    fi
}

repo_root_from_script() {
    local self="${BASH_SOURCE[0]:-}"
    if [[ -n "$self" && -f "$self" ]]; then
        local root
        root="$(cd "$(dirname "$self")/.." && pwd)"
        if [[ -f "$root/shell.qml" ]]; then
            printf '%s\n' "$root"
            return 0
        fi
    fi
    return 1
}

ensure_checkout() {
    if repo_root_from_script >/dev/null; then
        return 0
    fi
    command -v git >/dev/null 2>&1 || sudo pacman -Sy --noconfirm --needed git
    mkdir -p "$(dirname "$DATA_DIR")"
    if [[ -d "$DATA_DIR/.git" ]]; then
        git -C "$DATA_DIR" fetch origin "$REPO_BRANCH"
        git -C "$DATA_DIR" checkout "$REPO_BRANCH"
        git -C "$DATA_DIR" pull --ff-only origin "$REPO_BRANCH"
    else
        if [[ -e "$DATA_DIR" ]]; then
            die "$DATA_DIR já existe e não é um clone git."
        fi
        git clone --branch "$REPO_BRANCH" "$REPO_URL" "$DATA_DIR"
    fi
    exec bash "$DATA_DIR/install/install.sh"
}

choose_compositor() {
    say ""
    say "mwm-shell"
    say "Escolhe o compositor:"
    say "  1) Hyprland"
    say "  2) Sway   (ainda sem configuração)"
    say "  3) niri   (ainda sem configuração)"
    local choice
    read -r -p "Opção [1]: " choice
    choice="${choice:-1}"
    case "$choice" in
        1) COMPOSITOR="hyprland" ;;
        2|3)
            say "Este compositor ainda não é configurado. Escolhe Hyprland."
            choose_compositor
            ;;
        *)
            say "Opção inválida."
            choose_compositor
            ;;
    esac
}

aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        printf 'paru\n'
    elif command -v yay >/dev/null 2>&1; then
        printf 'yay\n'
    fi
}

install_quickshell() {
    if pacman -Q quickshell >/dev/null 2>&1 || pacman -Q quickshell-git >/dev/null 2>&1; then
        return 0
    fi
    if pacman -Si quickshell >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm quickshell
        return 0
    fi
    local helper
    helper="$(aur_helper || true)"
    if [[ -z "$helper" ]]; then
        die "quickshell não está nos repositórios. Instala paru ou yay e corre o instalador outra vez."
    fi
    "$helper" -S --needed --noconfirm quickshell-git
}

install_packages() {
    say "A instalar pacotes..."
    sudo pacman -Sy --needed --noconfirm "${pacman_pkgs[@]}"
    install_quickshell
    fc-cache -f >/dev/null 2>&1 || true
    sudo fc-cache -f >/dev/null 2>&1 || true
}

link_shell() {
    local root="$1"
    mkdir -p "$QS_DIR" "$MW_DIR"
    ln -sfn "$root" "$QS_LINK"
    if [[ ! -f "$MW_DIR/config.json" ]]; then
        cp "$root/config/config.json" "$MW_DIR/config.json"
    fi
}

write_snippet_lua() {
    local file="$1"
    mkdir -p "$(dirname "$file")"
    cat >"$file" <<'EOF'
-- mwm-shell:managed
-- Gerado pelo instalador. Volta a correr o instalador para o repor.

hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'mkdir -p \"$HOME/.local/state/mwm\" && exec qs -c mwm >> \"$HOME/.local/state/mwm/qs.log\" 2>&1'")
end)

hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd("qs -c mwm ipc call mwm toggle controlCenter"))
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("qs -c mwm ipc call mwm toggle media"))
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("qs -c mwm ipc call mwm toggle notifications"))

hl.layer_rule({
    name = "mwm-blur",
    match = { namespace = "mwm-(bar|control|media|osd|notifications)" },
    blur = true,
})
EOF
}

write_session_lua() {
    local file="$1"
    mkdir -p "$(dirname "$file")"
    cat >"$file" <<'EOF'
-- mwm-shell:managed
-- Sessão mínima para Hyprland 0.56+. Volta a correr o instalador para a repor.

local terminal = "kitty"
local mainMod = "SUPER"

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 1,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
        },
    },
    input = {
        kb_layout = "us",
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'mkdir -p \"$HOME/.local/state/mwm\" && exec qs -c mwm >> \"$HOME/.local/state/mwm/qs.log\" 2>&1'")
end)

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("qs -c mwm ipc call mwm toggle controlCenter"))
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd("qs -c mwm ipc call mwm toggle media"))
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("qs -c mwm ipc call mwm toggle notifications"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.layer_rule({
    name = "mwm-blur",
    match = { namespace = "mwm-(bar|control|media|osd|notifications)" },
    blur = true,
})
EOF
}

lua_is_managed() {
    local file="$1"
    [[ -f "$file" ]] && head -n 1 "$file" | grep -q "$MARKER"
}

park_generated_conf() {
    local classic="$1"
    if lua_is_managed "$classic"; then
        mv "$classic" "$classic.bak"
        say "O hyprland.conf gerado pelo instalador passou a $classic.bak"
    fi
}

configure_hyprland() {
    local lua_entry="$CONFIG_HOME/hypr/hyprland.lua"
    local user_lua="$HOME/.config/caelestia/hypr-user.lua"
    local classic="$CONFIG_HOME/hypr/hyprland.conf"
    local snippet_lua="$HOME/.config/mwm/hypr.lua"

    mkdir -p "$CONFIG_HOME/hypr"

    if [[ ! -f "$lua_entry" ]] || lua_is_managed "$lua_entry"; then
        write_session_lua "$lua_entry"
        park_generated_conf "$classic"
        say "Hyprland lê $lua_entry"
        return 0
    fi

    write_snippet_lua "$snippet_lua"
    mkdir -p "$(dirname "$user_lua")"
    touch "$user_lua"
    if ! grep -q "$MARKER" "$user_lua"; then
        cat >>"$user_lua" <<EOF

-- $MARKER
dofile(os.getenv("HOME") .. "/.config/mwm/hypr.lua")
EOF
    fi
    say "Hyprland (Lua existente) ligado em $user_lua"
}

enable_services() {
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now bluetooth.service >/dev/null 2>&1 || true
        sudo systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1 || true
        systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service >/dev/null 2>&1 || true
    fi
}

main() {
    need_arch
    ensure_checkout
    local root
    root="$(repo_root_from_script)"
    choose_compositor
    say ""
    read -r -p "Instalar pacotes e configurar o Hyprland? [S/n] " go
    go="${go:-S}"
    if [[ "$go" != "S" && "$go" != "s" && "$go" != "" ]]; then
        die "instalação cancelada."
    fi
    install_packages
    link_shell "$root"
    configure_hyprland
    enable_services
    say ""
    say "mwm-shell ficou instalada."
    say "Entra numa sessão Hyprland. A barra arranca sozinha."
    say "Atalhos: Super+Return terminal, Super+Alt+C controlo, Super+Alt+M media, Super+Alt+N notificações."
}

main "$@"

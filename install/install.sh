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
    qt6-base
    qt6-declarative
    qt6-5compat
    pipewire
    wireplumber
    networkmanager
    bluez
    bluez-utils
    brightnessctl
    inotify-tools
    power-profiles-daemon
    lm_sensors
    ttf-ibm-plex
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
    if [[ "$COMPOSITOR" == "hyprland" ]] && ! pacman -Q hyprland >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm hyprland
    fi
    install_quickshell
}

link_shell() {
    local root="$1"
    mkdir -p "$QS_DIR" "$MW_DIR"
    ln -sfn "$root" "$QS_LINK"
    if [[ ! -f "$MW_DIR/config.json" ]]; then
        cp "$root/config/config.json" "$MW_DIR/config.json"
    fi
}

write_hypr_conf() {
    local file="$1"
    cat >"$file" <<'EOF'
# mwm-shell:managed
# Gerado pelo instalador. Volta a correr o instalador para o repor.

exec-once = qs -c mwm

layerrule {
    name = mwm-blur
    match:namespace = mwm-(bar|control|media|osd|notifications)
    blur = on
}

bind = SUPER ALT, C, exec, qs -c mwm ipc call mwm toggle controlCenter
bind = SUPER ALT, M, exec, qs -c mwm ipc call mwm toggle media
bind = SUPER ALT, N, exec, qs -c mwm ipc call mwm toggle notifications
EOF
}

write_hypr_lua() {
    local file="$1"
    cat >"$file" <<'EOF'
-- mwm-shell:managed
-- Gerado pelo instalador. Volta a correr o instalador para o repor.

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c mwm")
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

append_once() {
    local file="$1"
    local line="$2"
    mkdir -p "$(dirname "$file")"
    touch "$file"
    if ! grep -q "$MARKER" "$file"; then
        printf '\n%s\n%s\n' "# $MARKER" "$line" >>"$file"
    fi
}

configure_hyprland() {
    # A Caelestia carrega sempre ~/.config, mesmo com XDG_CONFIG_HOME definido.
    local lua_entry="$HOME/.config/hypr/hyprland.lua"
    local user_lua="$HOME/.config/caelestia/hypr-user.lua"
    local classic="$CONFIG_HOME/hypr/hyprland.conf"
    local snippet_conf="$CONFIG_HOME/hypr/mwm.conf"
    local snippet_lua="$HOME/.config/mwm/hypr.lua"

    if [[ -f "$lua_entry" ]]; then
        write_hypr_lua "$snippet_lua"
        mkdir -p "$(dirname "$user_lua")"
        touch "$user_lua"
        if ! grep -q "$MARKER" "$user_lua"; then
            cat >>"$user_lua" <<EOF

-- $MARKER
dofile(os.getenv("HOME") .. "/.config/mwm/hypr.lua")
EOF
        fi
        say "Hyprland (Lua) ligado em $user_lua"
        return 0
    fi

    mkdir -p "$CONFIG_HOME/hypr"
    write_hypr_conf "$snippet_conf"
    if [[ ! -f "$classic" ]]; then
        cat >"$classic" <<EOF
# $MARKER
source = ~/.config/hypr/mwm.conf

monitor = ,preferred,auto,1

decoration {
    blur {
        enabled = true
        size = 8
        passes = 2
    }
}
EOF
        say "Criei $classic com arranque, blur e atalhos."
        return 0
    fi

    append_once "$classic" "source = ~/.config/hypr/mwm.conf"
    say "Hyprland ligado em $classic"
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
    say "Atalhos: Super+Alt+C controlo, Super+Alt+M media, Super+Alt+N notificações."
}

main "$@"

# mwm-shell

Shell de desktop para Wayland, escrita em [Quickshell](https://quickshell.outfoxxed.me). O alvo é Arch Linux e CachyOS com Hyprland. A interface é uma ferramenta de trabalho: quadrada, densa e silenciosa.

O código é original. Caelestia e Serpantinum serviram de referência de arquitetura, não de cópia.

## Pilares

- **Performance.** Um processo de render threaded, sem plugin C++, sem animações infinitas. CPU, RAM e temperatura só são lidos enquanto o módulo de estatísticas está montado na barra.
- **Produtividade.** Workspaces por monitor, relógio, tabuleiro do sistema e leitura curta de recursos. Os módulos seguintes (atalhos de terminal, estado Git) entram na mesma barra.
- **Media.** O painel MPRIS mostra capa, metadados, progresso clicável e o mixer por aplicação.
- **Estética.** Bordas retas (`Theme.radius` é 0). Superfícies escuras e translúcidas para o blur do Hyprland. IBM Plex Sans na interface, IBM Plex Mono nos números.

## Estado

Milestone 1: Hyprland, barra, centro de controlo, MPRIS, OSD e notificações. O calendário ainda não tem painel.

## Pré-visualização

As imagens abaixo são placeholders. Substituem-se por capturas reais quando a shell estiver a correr no compositor.

![Barra superior](assets/screenshots/bar.svg)

![Centro de controlo](assets/screenshots/control-center.svg)

![Leitor de media](assets/screenshots/media.svg)

## Dependências

CachyOS e Arch. `quickshell-git` está no AUR; em CachyOS pode existir nos repositórios da distribuição.

```sh
paru -S --needed \
  quickshell-git \
  qt6-base \
  qt6-declarative \
  qt6-5compat \
  pipewire \
  wireplumber \
  networkmanager \
  bluez \
  brightnessctl \
  inotify-tools \
  power-profiles-daemon \
  lm_sensors \
  ttf-ibm-plex \
  ttf-material-symbols-variable
```

`lm_sensors` não é chamado pela barra. O script lê `/proc` e `/sys`. O pacote serve para `sensors-detect` expor o hwmon do CPU. `inotify-tools` deixa o brilho reagir a alterações no sysfs sem um timer. Os ícones da barra são desenhados em QML.

## Instalação

```sh
git clone <url-deste-repositório> ~/Projectos/mwm-shell
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
ln -sfn ~/Projectos/mwm-shell "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/mwm"
qs -c mwm
```

Para arrancar com a sessão, no Hyprland:

```lua
hl.on("hyprland.start", function()
  os.execute("qs -c mwm &")
end)
```

## Blur

A barra usa a namespace de layer `mwm-bar` e uma cor com alfa 0.72. O blur é do compositor, não um filtro da shell.

```lua
hl.layer_rule({
  match = { namespace = "mwm-(bar|control|media|osd|notifications)" },
  blur = true,
})
```

Em `hyprland.conf` recente o equivalente é:

```
layerrule {
    match:namespace = mwm-(bar|control|media|osd|notifications)
    blur = on
}
```

O tamanho e o número de passagens ficam na secção `decoration.blur` do Hyprland.

## Configuração

Os valores por omissão vivem em `core/Config.qml`. Para os substituir, copia [`config/config.json`](config/config.json) para `~/.config/mwm/config.json` (`$XDG_CONFIG_HOME/mwm/config.json` se a variável existir). A posição da barra é `bar.position`: `"top"` ou `"bottom"`.

Cores, fontes, espaçamento e `radius` estão só em [`styles/Theme.qml`](styles/Theme.qml).

IPC, com a shell a correr:

```sh
qs -c mwm ipc call mwm toggle controlCenter
qs -c mwm ipc call mwm toggle media
qs -c mwm ipc call mwm toggle notifications
qs -c mwm ipc call mwm toggle dnd
qs -c mwm ipc call mwm barPosition
```

`toggle` aceita `controlCenter`, `media`, `notifications`, `dnd` e `calendar`. O calendário ainda não abre um painel.

## Estrutura

```
shell.qml            entrada, uma janela por ecrã
styles/Theme.qml     cor, tipo, radius 0
core/Config.qml      comportamento, incluindo a posição da barra
core/Compositor.qml  fachada Hyprland
core/ShellState.qml  estado global
core/ScreenState.qml estado por ecrã
components/          primitivos de interface
services/            estado de sistema
modules/bar/         barra
modules/controlcenter/
modules/media/
modules/osd/
modules/notifications/
scripts/             leitores que não têm barramento de eventos
```

## Licença

MIT. Ver [LICENSE](LICENSE).

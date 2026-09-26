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

## Instalação

Arch Linux ou CachyOS. Um comando: o instalador pergunta o compositor, instala os pacotes e deixa o Hyprland a arrancar a shell.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mora1ss/mwm-shell/main/install/install.sh)"
```

Nesta versão a opção que configura a sessão é o Hyprland. Sway e niri aparecem na lista e ainda não escrevem configuração. No fim, entra numa sessão Hyprland. A barra sobe sozinha.

Atalhos escritos em `~/.config/hypr/hyprland.lua`:

| Atalho | Ação |
| --- | --- |
| Super+Return | Terminal (kitty) |
| Super+Alt+C | Centro de controlo |
| Super+Alt+M | Media |
| Super+Alt+N | Notificações |

O blur das namespaces `mwm-bar`, `mwm-control`, `mwm-media`, `mwm-osd` e `mwm-notifications` fica no mesmo Lua. Se já existir um `hyprland.lua` teu, o bloco da shell entra em `~/.config/caelestia/hypr-user.lua`. Um `hyprland.conf` criado por este instalador é renomeado para `hyprland.conf.bak`, para o Hyprland 0.56 ler o Lua.

Para atualizar uma máquina que já clonou a shell:

```bash
git -C ~/.local/share/mwm-shell pull
bash ~/.local/share/mwm-shell/install/install.sh
```

Depois entra numa sessão Hyprland nova.

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
install/install.sh   instalador Arch/CachyOS
```

## Licença

MIT. Ver [LICENSE](LICENSE).

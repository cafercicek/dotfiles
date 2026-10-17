# startup

Fresh Linux/WSL bootstrap: shell config, Neovim, Herdr, and the tools I use daily.

Monorepo — `configs/nvim` and `configs/herdr` live in-tree (no git submodules).

## What you get

| Piece | How |
|-------|-----|
| `~/.bashrc` | Symlink to `config/bashrc` |
| `~/.config/nvim` | Symlink to `configs/nvim` |
| `~/.config/herdr` | Symlink to `configs/herdr` |
| apps + optional tools | `scripts/install-*.sh` via Just |

Machine-specific paths (TI, Android, Obsidian, WSL) live in `~/.bashrc.local` (from `config/bashrc.local.example`).

## Choose what to install

Edit `config/install.config`:

- `[apps]` — tools (`cargo`, `nvim`, `plantuml`, …)
- `[configs]` — links (`bashrc`, `nvim`, `herdr`)

Comment a line with `#` to skip it. Then:

```bash
just all      # enabled apps + enabled configs
just apps     # apps only
just link     # configs only
```

Optional apps (commented by default): `plantuml`, `obsidian`, `usbipd`, `udev-xds`.

## New machine

After cloning this repo into `~/startup`:

```bash
cd ~/startup

# if just is missing:
bash scripts/install-cargo.sh
bash scripts/install-just.sh

# optional: edit config/install.config first
just all
exec bash
```

## Just recipes

| Recipe | Action |
|--------|--------|
| `just status` | Tools + identity + docker group + `ssh -T git@github.com` |
| `just apps` | Install apps enabled in `config/install.config` |
| `just link` | Link configs enabled in `config/install.config` (backs up existing) |
| `just all` | `apps` + `link` from `config/install.config` |
| `just install-plantuml` | apt PlantUML (+ JRE) |
| `just install-obsidian` | Obsidian AppImage → `~/obsidian_local` |
| `just install-gh` | Install GitHub CLI (`gh`) |
| `just util_git_identity "Name" you@example.com` | Set global `git` user.name / user.email |
| `just util_ssh_key you@example.com` | Create `~/.ssh/id_ed25519` if missing; print public key |
| `just util_docker_user_access` | Add user to `docker` group (then re-login / `newgrp docker`) |
| `just util_docker_login ghp_xxxx` | `docker login` to ghcr.io |
| `just util_gh_login ghp_xxxx` | `gh auth login --with-token` |
| `just util_usbipd list` | List Windows USB devices (WSL) |
| `just util_usbipd <BUSID>` | Attach device to WSL (`d`/`b`/`u` for detach/bind/unbind) |
| `just install-usbipd` | Install usbipd-win on Windows host |
| `just install-udev-xds` | XDS110 udev rules → `/dev/xds_uart_*` |

## Layout

```
config/install.config         what just all / apps / link runs
config/bashrc                 portable shell config (no secrets)
config/bashrc.local.example   machine overrides template
scripts/install-*.sh          one script per tool
scripts/bootstrap-from-config.sh
configs/nvim                  Neovim config (in-tree)
configs/herdr                 Herdr config (in-tree)
```

## Notes

- Secrets never go in this repo. Put tokens in `~/.bashrc.local` (gitignored) or a secret manager.
- `just link` renames existing `~/.bashrc`, `~/.config/nvim`, `~/.config/herdr` to `*.bak.<timestamp>` before linking.
- After `just install-obsidian` / `just install-plantuml`, enable the aliases in `~/.bashrc.local` (see example).

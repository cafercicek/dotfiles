set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

root := justfile_directory()

# Show which tools are installed
status:
    bash "{{root}}/scripts/status.sh"

# Install individual tools
install-cargo:
    bash "{{root}}/scripts/install-cargo.sh"

install-just:
    bash "{{root}}/scripts/install-just.sh"

install-docker:
    bash "{{root}}/scripts/install-docker.sh"

# Add $USER to docker group (sudo usermod). Re-login / newgrp after.
# Usage: just util_docker_user_access
util_docker_user_access:
    bash "{{root}}/scripts/util-docker-user-access.sh"

install-gh:
    bash "{{root}}/scripts/install-gh.sh"

install-nvim:
    bash "{{root}}/scripts/install-nvim.sh"

install-zoxide:
    bash "{{root}}/scripts/install-zoxide.sh"

install-fzf:
    bash "{{root}}/scripts/install-fzf.sh"

install-herdr:
    bash "{{root}}/scripts/install-herdr.sh"

install-cursor-agent:
    bash "{{root}}/scripts/install-cursor-agent.sh"

install-clangd:
    bash "{{root}}/scripts/install-clangd.sh"

install-plantuml:
    bash "{{root}}/scripts/install-plantuml.sh"

install-obsidian:
    bash "{{root}}/scripts/install-obsidian.sh"

# XDS110 multi-MCU udev symlinks (/dev/xds_uart_*)
install-udev-xds:
    bash "{{root}}/scripts/install-udev-xds.sh"

[private]
util_create_udev_rules_for_multi_mcu: install-udev-xds

# Symlink configs enabled in config/install.config [configs]
link:
    bash "{{root}}/scripts/bootstrap-from-config.sh" configs

# Install apps enabled in config/install.config [apps]
apps:
    bash "{{root}}/scripts/bootstrap-from-config.sh" apps

# Full bootstrap from config/install.config ([apps] then [configs])
all:
    bash "{{root}}/scripts/bootstrap-from-config.sh" all

# Global git identity (user.name / user.email). Not part of `just all`.
# Usage: just util_git_identity "Full Name" you@example.com
util_git_identity NAME EMAIL:
    bash "{{root}}/scripts/util-git-identity.sh" "{{NAME}}" "{{EMAIL}}"

# Create ~/.ssh/id_ed25519 if missing; print public key. Not part of `just all`.
# Usage: just util_ssh_key you@example.com
util_ssh_key EMAIL:
    bash "{{root}}/scripts/util-ssh-key.sh" "{{EMAIL}}"

# GitHub classic token with read:packages (ghcr.io container registry).
# Usage: just util_docker_login ghp_xxxx
util_docker_login ARG:
    echo "{{ARG}}" | docker login ghcr.io -u user --password-stdin

# GitHub classic token for gh CLI (repo/read scopes as needed).
# Usage: just util_gh_login ghp_xxxx
util_gh_login ARG:
    echo "{{ARG}}" | gh auth login --with-token

# Generate bash completions for just (~/.just-completion.bash).
# config/bashrc already sources that file — does not append to ~/.bashrc.
[private]
util_autocompletion_just:
    #!/usr/bin/env bash
    set -euo pipefail
    just --completions bash > ~/.just-completion.bash
    echo "Wrote ~/.just-completion.bash"
    echo "Reload with: source ~/.bashrc  (or open a new terminal)"

# WSL <-> Windows USB sharing via usbipd-win.
# Usage:
#   just util_usbipd list
#   just util_usbipd <BUSID>       # attach to WSL
#   just util_usbipd <BUSID> d     # detach
#   just util_usbipd <BUSID> b     # bind (admin)
#   just util_usbipd <BUSID> u     # unbind (admin)
#   just util_usbipd help
util_usbipd BUSID="list" COMMAND="":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [ "{{BUSID}}" == "h" ] || [ "{{BUSID}}" == "help" ]; then
      echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
      echo -e "\033[1;33m  USBIPD Usage:\033[0m"
      echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
      echo -e "\033[1;32m  List devices:\033[0m"
      echo -e "    just util_usbipd list"
      echo -e ""
      echo -e "\033[1;32m  Attach device to WSL:\033[0m"
      echo -e "    just util_usbipd <BUSID>"
      echo -e ""
      echo -e "\033[1;32m  Detach device:\033[0m"
      echo -e "    just util_usbipd <BUSID> d"
      echo -e ""
      echo -e "\033[1;32m  Bind device:\033[0m"
      echo -e "    just util_usbipd <BUSID> b"
      echo -e ""
      echo -e "\033[1;32m  Unbind device:\033[0m"
      echo -e "    just util_usbipd <BUSID> u"
      echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    elif [ "{{BUSID}}" == "list" ]; then
      powershell.exe -Command "usbipd.exe list"
    elif [ "{{COMMAND}}" == "d" ]; then
      powershell.exe -Command "Start-Process usbipd.exe -ArgumentList 'detach -b {{BUSID}}'  -Wait"
    elif [ "{{COMMAND}}" == "b" ]; then
      powershell.exe -Command "Start-Process usbipd.exe -ArgumentList 'bind -b {{BUSID}}' -Verb runAs -Wait"
    elif [ "{{COMMAND}}" == "u" ]; then
      powershell.exe -Command "Start-Process usbipd.exe -ArgumentList 'unbind -b {{BUSID}}' -Verb runAs -Wait"
    else
      powershell.exe -Command "Start-Process usbipd.exe -ArgumentList 'attach --wsl -b {{BUSID}}'  -Wait"
    fi

# Install usbipd-win on the Windows host (WSL). Optional in config/install.config.
install-usbipd: util_check_usbipd_app

[private]
util_check_usbipd_app:
    #!/usr/bin/env bash
    set -euxo pipefail
    if ! which usbipd.exe > /dev/null 2>&1; then
      echo "'usbipd' is not installed. Downloading and installing now..."
      mkdir -p /mnt/c/Users/Public/util/tools
      wget -O /mnt/c/Users/Public/util/tools/usbipd-win.msi "https://github.com/dorssel/usbipd-win/releases/download/v5.3.0/usbipd-win_5.3.0_x64.msi"
      powershell.exe -Command "Start-Process msiexec -ArgumentList '/i C:\\Users\\Public\\util\\tools\\usbipd-win.msi /qn' -Verb runAs -Wait"
      echo "usbipd installed."
    else
      echo "usbipd is already installed."
    fi

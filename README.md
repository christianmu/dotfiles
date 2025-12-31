# dotfiles

Personal dotfiles and command-line tools for my Linux setup.

This repository contains shell configuration, scripts and helpers that are
symlinked into the home directory on a new machine.

---

## Setup (new machine)

```bash
git clone git@github.com:christianmu/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup-dotfiles.sh
./setup-dotfiles.sh

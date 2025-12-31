#!/usr/bin/env bash
set -e

echo "🔧 Setting up dotfiles…"
echo

DOTFILES_DIR="$HOME/dotfiles"

# --- sanity checks -----------------------------------------------------------

if [ ! -d "$DOTFILES_DIR" ]; then
  echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
  exit 1
fi

# --- helper ------------------------------------------------------------------

link() {
  local source="$1"
  local target="$2"

  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "ℹ️  Skipping: $target already exists"
  else
    ln -s "$source" "$target"
    echo "✅ Linked: $target → $source"
  fi
}

# --- bin ---------------------------------------------------------------------

echo "📁 bin"
link "$DOTFILES_DIR/bin" "$HOME/bin"
echo

# --- bash --------------------------------------------------------------------

echo "🐚 bash"
link "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"
echo

# --- done --------------------------------------------------------------------

echo "🎉 Dotfiles setup complete."

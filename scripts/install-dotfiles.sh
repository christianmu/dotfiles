link_file () {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ]; then
    echo "✅ Symlink exists: $dst"
    return
  fi

  if [ -e "$dst" ]; then
    local backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "🧰 Backing up existing: $dst -> $backup"
    mv "$dst" "$backup"
  fi

  echo "🔗 Linking: $dst -> $src"
  ln -s "$src" "$dst"
}

# Git
link_file "$HOME/dotfiles/git/gitconfig" "$HOME/.gitconfig"

# Create local overrides placeholder if missing
if [ ! -f "$HOME/.gitconfig.local" ]; then
  cat > "$HOME/.gitconfig.local" <<'EOL'
# Machine-specific Git settings go here.
# Example:
# [safe]
#   directory = /some/path
EOL
  echo "📝 Created $HOME/.gitconfig.local (edit as needed)"
fi

# Bash
link_file "$HOME/dotfiles/bash/bashrc" "$HOME/.bashrc"

# Create local bash overrides if missing
if [ ! -f "$HOME/.bashrc.local" ]; then
  cat > "$HOME/.bashrc.local" <<'EOF'
# Local bash settings (not versioned)
EOF
  echo "📝 Created ~/.bashrc.local"
fi

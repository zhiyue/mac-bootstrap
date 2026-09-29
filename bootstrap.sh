#!/usr/bin/env bash
# bootstrap.sh — bare macOS -> existing dotfiles setup.
# Installs Xcode CLT, Homebrew, Git, gh, Python 3, age and 1Password CLI.
# Cloning and setup remain opt-in through DEV_SETUP_REPO.
# DEV_SETUP_DIR and DEV_SETUP_SOURCE select the checkout location.
# DOTFILES_AGE_IDENTITY optionally supplies a local identity file to setup.sh.
set -euo pipefail

DEST="${DEV_SETUP_DIR:-$HOME/workspace/dev-setup}"
SOURCE="${DEV_SETUP_SOURCE:-$DEST/mac-dotfiles}"

log()  { printf '\033[0;34mℹ %s\033[0m\n' "$*"; }
ok()   { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m⚠ %s\033[0m\n' "$*"; }
die()  { printf '\033[0;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[[ "$OSTYPE" == darwin* ]] || die "macOS only."

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return
  fi
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then
      printf '%s\n' "$b"
      return
    fi
  done
}

# 1) Xcode Command Line Tools (provides git, clang) --------------------------
if xcode-select -p >/dev/null 2>&1; then
  ok "Command Line Tools present"
else
  log "Installing Command Line Tools — complete the GUI dialog that appears…"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 15; done
  ok "Command Line Tools installed"
fi

# 2) Homebrew ----------------------------------------------------------------
brew_bin="$(find_brew || true)"
if [[ -z "$brew_bin" ]]; then
  log "Installing Homebrew (may prompt for your password)…"
  sudo -v || die "Administrator sudo access is required to install Homebrew."
  if ! NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    die "Homebrew install failed. If it mentioned another brew update process, wait for it to finish, then rerun this script."
  fi
  brew_bin="$(find_brew || true)"
fi
if [[ -n "$brew_bin" ]]; then eval "$("$brew_bin" shellenv)"; fi
command -v brew >/dev/null 2>&1 || die "Homebrew not on PATH after install."
ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"

# 3) Core toolchain ----------------------------------------------------------
for pkg in git gh python age; do
  if brew list --versions "$pkg" >/dev/null 2>&1; then
    ok "$pkg present"
  else
    log "brew install ${pkg}…"
    brew install "$pkg"
  fi
done
cask=1password-cli
if brew list --cask --versions "$cask" >/dev/null 2>&1; then
  ok "$cask present"
else
  log "brew install --cask ${cask}…"
  brew install --cask "$cask"
fi

# 4) Optional: clone + explicit setup (only when DEV_SETUP_REPO is set) ------
if [[ -z "${DEV_SETUP_REPO:-}" ]]; then
  cat <<EOF

$(ok "Toolchain ready.")  Repo not cloned (DEV_SETUP_REPO unset).
Next:
  gh auth login                                  # or load an SSH key from 1Password
  git clone <your-dotfiles-repo> "$SOURCE"
  ( cd "$SOURCE" && ./setup.sh --identity /path/to/local-identity )
Then install the packages and tools described in the dotfiles README.
EOF
  exit 0
fi

if [[ ! -d "$SOURCE/.git" ]]; then
  case "$DEV_SETUP_REPO" in
    https://github.com/*|git@github.com:*)
      gh auth status >/dev/null 2>&1 || { log "GitHub auth…"; gh auth login; } ;;
  esac
  log "Cloning $DEV_SETUP_REPO → $SOURCE"
  mkdir -p "$(dirname "$SOURCE")"
  git clone "$DEV_SETUP_REPO" "$SOURCE"
else
  ok "Repo already at $SOURCE"
fi

[[ -f "$SOURCE/setup.sh" ]] || die "This checkout has no setup.sh. Use the migrated mac-dotfiles revision."
log "Explicit dotfiles setup (source: $SOURCE)…"
if [[ -n "${DOTFILES_AGE_IDENTITY:-}" ]]; then
  bash "$SOURCE/setup.sh" --identity "$DOTFILES_AGE_IDENTITY"
else
  bash "$SOURCE/setup.sh"
fi

cat <<EOF

$(ok "Core bootstrap done.")  Remaining manual steps (see the dotfiles README):
  • 1Password: open the app, unlock, enable CLI  →  op account list
  • Packages:  brew bundle --file="$SOURCE/Brewfile"{,.fonts,.vscode}
  • Tools:     ( cd "$SOURCE" && ./install-tools.sh )
EOF

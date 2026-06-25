#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$HERE/publish-talk.sh"
mkdir -p "$HOME/.local/bin"
ln -sf "$HERE/publish-talk.sh" "$HOME/.local/bin/publish-talk"
echo "Installed publish-talk -> $HOME/.local/bin/publish-talk"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "WARN: \$HOME/.local/bin is not on PATH; add it to your shell rc";;
esac

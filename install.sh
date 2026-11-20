#!/bin/sh
# waggle installer. Downloads the client for this machine, checks it against the published
# SHA-256 list, and installs it to ~/.waggle/bin/waggle.
#
#   curl -fsSL <release url>/install.sh | sh
#
# WAGGLE_RELEASE_URL overrides where the files come from (it must serve waggle-<os>-<arch>
# and SHA256SUMS, as tools/release.sh writes them into dist/).
set -eu
URL="${WAGGLE_RELEASE_URL:-https://github.com/Iustin-Epanu/waggle/releases/download/v0.3.2}"
case "$URL" in __*) echo "waggle: no release address is set. Run with WAGGLE_RELEASE_URL=<url>." >&2; exit 1;; esac
os="$(uname -s | tr 'A-Z' 'a-z')"; arch="$(uname -m)"
case "$arch" in x86_64|amd64) arch=amd64;; aarch64|arm64) arch=arm64;; *) echo "waggle: unsupported processor: $arch" >&2; exit 1;; esac
exe=""
case "$os" in darwin|linux) ;; mingw*|msys*|cygwin*) os=windows; exe=".exe";; *) echo "waggle: unsupported system: $os (macOS, Linux, and Windows under Git Bash)" >&2; exit 1;; esac
file="waggle-$os-$arch$exe"
dir="$HOME/.waggle/bin"; mkdir -p "$dir"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
echo "downloading $file ..."
curl -fsSL "$URL/$file" -o "$tmp/$file"
curl -fsSL "$URL/SHA256SUMS" -o "$tmp/SHA256SUMS"
want="$(awk -v f="$file" '$2==f {print $1}' "$tmp/SHA256SUMS")"
if command -v sha256sum >/dev/null 2>&1; then got="$(sha256sum "$tmp/$file" | awk '{print $1}')"; else got="$(shasum -a 256 "$tmp/$file" | awk '{print $1}')"; fi
if [ -z "$want" ] || [ "$want" != "$got" ]; then echo "waggle: checksum mismatch for $file. Nothing was installed." >&2; exit 1; fi
chmod +x "$tmp/$file"
if [ -n "$exe" ] && [ -f "$dir/waggle$exe" ]; then
  # Windows will not replace a program that is running (the waggle service), but it lets it be
  # renamed: move the old one aside; the service sees the new file and stops within seconds
  rm -f "$dir"/waggle-old-*.exe 2>/dev/null || true
  mv "$dir/waggle$exe" "$dir/waggle-old-$$.exe"
fi
mv "$tmp/$file" "$dir/waggle$exe"
echo "installed waggle $("$dir/waggle$exe" version) at $dir/waggle$exe"
# Put waggle on PATH: a link in ~/.local/bin when that folder is already on PATH, otherwise one
# line in the shell's profile (once). WAGGLE_NO_MODIFY_PATH=1 leaves the profile alone.
onpath=""
case ":$PATH:" in *":$dir:"*) onpath=1;; esac
if [ -z "$onpath" ] && [ -z "$exe" ]; then case ":$PATH:" in *":$HOME/.local/bin:"*) mkdir -p "$HOME/.local/bin" && ln -sf "$dir/waggle" "$HOME/.local/bin/waggle" && onpath=1;; esac; fi
if [ -n "$exe" ] && [ -z "${WAGGLE_NO_MODIFY_PATH:-}" ] && command -v powershell.exe >/dev/null 2>&1; then
  # cmd and PowerShell read the user's Path from the registry, not from a shell profile
  windir="$(cygpath -w "$dir" 2>/dev/null || echo "$dir")"
  WAGGLE_DIR="$windir" powershell.exe -NoProfile -NonInteractive -Command '$d=$env:WAGGLE_DIR; $p=[Environment]::GetEnvironmentVariable("Path","User"); if (-not $p) { $p="" }; if (($p -split ";") -notcontains $d) { [Environment]::SetEnvironmentVariable("Path", ($p.TrimEnd(";") + ";" + $d).TrimStart(";"), "User"); Write-Output "added $d to your Path for cmd and PowerShell (open a new window)" }' || true
fi
if [ -z "$onpath" ]; then
  line='export PATH="$HOME/.waggle/bin:$PATH"'
  case "${SHELL:-}" in */zsh) prof="$HOME/.zshrc";; */bash) prof="$HOME/.bashrc"; [ "$(uname -s)" = Darwin ] && prof="$HOME/.bash_profile";; *) prof="$HOME/.profile";; esac
  if [ -n "${WAGGLE_NO_MODIFY_PATH:-}" ]; then
    echo "Add waggle to your PATH:  $line"
  elif ! grep -qs '.waggle/bin' "$prof"; then
    printf '\n# waggle\n%s\n' "$line" >> "$prof"
    echo "added $dir to PATH in $prof (open a new terminal, or run: $line)"
  fi
fi
cat <<'EOT'

Next:
  1. Start a team:     waggle team create <team-name> <your-name>
     or join one:      waggle join <invite from your admin> <your-name>
  2. Add the plugin:   claude plugin marketplace add Iustin-Epanu/waggle
                       claude plugin install waggle@waggle
  3. Allow the command in the project's .claude/settings.json:
       { "permissions": { "allow": ["Bash(waggle:*)"] } }
  4. Check:            waggle doctor
  Another agent instead of Claude Code: waggle setup codex | gemini | antigravity | copilot | cursor
                                        (waggle setup mcp prints the entry for any other MCP client)
EOT

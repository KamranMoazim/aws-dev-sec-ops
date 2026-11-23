#!/usr/bin/env bash
# Usage: install-tools.sh [tool ...]   tools: trivy gitleaks semgrep checkov (default: all)
# Installs pinned versions into $TOOLS_DIR (default .tools); release binaries are checksum-verified.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/versions.env"
TOOLS_DIR="${TOOLS_DIR:-$(cd "$script_dir/../.." && pwd)/.tools}"
mkdir -p "$TOOLS_DIR/bin"
tools=("$@")
if [ ${#tools[@]} -eq 0 ]; then
  tools=(trivy gitleaks semgrep checkov)
fi

case "$(uname -s)" in
  Linux) trivy_os="Linux"; gitleaks_os="linux" ;;
  Darwin) trivy_os="macOS"; gitleaks_os="darwin" ;;
  *) echo "Unsupported OS $(uname -s)"; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) trivy_arch="64bit"; gitleaks_arch="x64" ;;
  arm64 | aarch64) trivy_arch="ARM64"; gitleaks_arch="arm64" ;;
  *) echo "Unsupported arch $(uname -m)"; exit 1 ;;
esac

download_verified() {
  local base_url="$1" asset="$2" checksums="$3" work_dir="$4"
  curl -fsSL -o "$work_dir/$asset" "$base_url/$asset"
  curl -fsSL -o "$work_dir/checksums.txt" "$base_url/$checksums"
  (cd "$work_dir" && grep " $asset\$" checksums.txt | shasum -a 256 -c -)
  tar -xzf "$work_dir/$asset" -C "$work_dir"
}

install_trivy() {
  local work_dir asset
  work_dir="$(mktemp -d)"
  asset="trivy_${TRIVY_VERSION}_${trivy_os}-${trivy_arch}.tar.gz"
  download_verified "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}" \
    "$asset" "trivy_${TRIVY_VERSION}_checksums.txt" "$work_dir"
  install -m 0755 "$work_dir/trivy" "$TOOLS_DIR/bin/trivy"
  mkdir -p "$TOOLS_DIR/share/trivy"
  cp "$work_dir/contrib/junit.tpl" "$TOOLS_DIR/share/trivy/junit.tpl"
  rm -rf "$work_dir"
}

install_gitleaks() {
  local work_dir asset
  work_dir="$(mktemp -d)"
  asset="gitleaks_${GITLEAKS_VERSION}_${gitleaks_os}_${gitleaks_arch}.tar.gz"
  download_verified "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}" \
    "$asset" "gitleaks_${GITLEAKS_VERSION}_checksums.txt" "$work_dir"
  install -m 0755 "$work_dir/gitleaks" "$TOOLS_DIR/bin/gitleaks"
  rm -rf "$work_dir"
}

# Each Python tool gets its own venv; semgrep and checkov pin conflicting dependencies.
install_python_tool() {
  local name="$1" package="$2" venv="$TOOLS_DIR/venv-$1"
  if [ ! -x "$venv/bin/pip" ]; then
    "${PYTHON:-python3}" -m venv "$venv"
  fi
  "$venv/bin/pip" install --quiet --disable-pip-version-check "$package"
  ln -sf "$venv/bin/$name" "$TOOLS_DIR/bin/$name"
}

for tool in "${tools[@]}"; do
  case "$tool" in
    trivy) install_trivy ;;
    gitleaks) install_gitleaks ;;
    semgrep) install_python_tool semgrep "semgrep==${SEMGREP_VERSION}" ;;
    checkov) install_python_tool checkov "checkov==${CHECKOV_VERSION}" ;;
    *) echo "Unknown tool $tool"; exit 1 ;;
  esac
done
echo "Installed: ${tools[*]} into $TOOLS_DIR"

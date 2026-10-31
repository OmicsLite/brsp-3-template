#!/usr/bin/env bash
# BRSP codespace setup: runs once, automatically, when a codespace is created.
# Installs the BRSP tools into their own environment (~/brsp-env):
#   Week 2: Prokka, NCBI Datasets   Week 3: seqkit, MAFFT, FastTree
# Full log: ~/brsp-setup.log
set -euo pipefail

ENV_DIR="$HOME/brsp-env"
LOG="$HOME/brsp-setup.log"
MM_DIR="$HOME/.micromamba"

echo "BRSP setup: installing bioinformatics tools (about 2-5 minutes)..."
echo "Full log: $LOG"

# zip/unzip are needed to unpack NCBI downloads and bundle results
if ! command -v unzip > /dev/null || ! command -v zip > /dev/null; then
  sudo apt-get update -qq >> "$LOG" 2>&1
  sudo apt-get install -y -qq unzip zip >> "$LOG" 2>&1
fi

# micromamba: a small, fast conda installer (pinned version)
mkdir -p "$MM_DIR"
curl -sSL -o "$MM_DIR/micromamba.tar.bz2" \
  "https://conda.anaconda.org/conda-forge/linux-64/micromamba-1.5.10-0.tar.bz2"
tar -xjf "$MM_DIR/micromamba.tar.bz2" -C "$MM_DIR" bin/micromamba
export MAMBA_ROOT_PREFIX="$MM_DIR/root"

"$MM_DIR/bin/micromamba" create -y -q -p "$ENV_DIR" \
  -c conda-forge -c bioconda --strict-channel-priority \
  prokka=1.15.6 ncbi-datasets-cli seqkit mafft fasttree >> "$LOG" 2>&1

# Free disk space: remove downloaded package files (the tools stay installed)
"$MM_DIR/bin/micromamba" clean -y -a >> "$LOG" 2>&1 || true
rm -f "$MM_DIR/micromamba.tar.bz2"

# Make the tools available in every terminal, even outside VS Code
if ! grep -qs "brsp-env" "$HOME/.bashrc"; then
  {
    echo ''
    echo '# BRSP tools'
    echo "export PATH=\"$ENV_DIR/bin:\$PATH\""
    echo 'export JAVA_TOOL_OPTIONS="-Xlog:disable -Xlog:all=warning:stderr"'
  } >> "$HOME/.bashrc"
fi

# Check the install worked
export PATH="$ENV_DIR/bin:$PATH"
export JAVA_TOOL_OPTIONS="-Xlog:disable -Xlog:all=warning:stderr"
prokka --version
datasets --version
seqkit version
mafft --version
FastTree -expert 2>&1 | head -n 1
echo "BRSP setup complete. Open a terminal and start with week2/week2_annotation.sh"

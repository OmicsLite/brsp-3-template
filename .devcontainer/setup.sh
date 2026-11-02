#!/usr/bin/env bash
# Setup codespace BRSP: berjalan sekali, otomatis, saat codespace dibuat.
# Meng-install tools BRSP ke environment tersendiri (~/brsp-env):
#   Minggu 2: Prokka, NCBI Datasets   Minggu 3: seqkit, MAFFT, FastTree
# Log lengkap: ~/brsp-setup.log
set -euo pipefail

ENV_DIR="$HOME/brsp-env"
LOG="$HOME/brsp-setup.log"
MM_DIR="$HOME/.micromamba"

echo "Setup BRSP: meng-install tools bioinformatika (sekitar 2-5 menit)..."
echo "Log lengkap: $LOG"

# zip/unzip dibutuhkan untuk membuka unduhan NCBI dan membungkus hasil
if ! command -v unzip > /dev/null || ! command -v zip > /dev/null; then
  sudo apt-get update -qq >> "$LOG" 2>&1
  sudo apt-get install -y -qq unzip zip >> "$LOG" 2>&1
fi

# micromamba: installer conda yang kecil dan cepat (versi dikunci)
mkdir -p "$MM_DIR"
curl -sSL -o "$MM_DIR/micromamba.tar.bz2" \
  "https://conda.anaconda.org/conda-forge/linux-64/micromamba-1.5.10-0.tar.bz2"
tar -xjf "$MM_DIR/micromamba.tar.bz2" -C "$MM_DIR" bin/micromamba
export MAMBA_ROOT_PREFIX="$MM_DIR/root"

"$MM_DIR/bin/micromamba" create -y -q -p "$ENV_DIR" \
  -c conda-forge -c bioconda --strict-channel-priority \
  prokka=1.15.6 ncbi-datasets-cli seqkit mafft fasttree >> "$LOG" 2>&1

# Hemat ruang disk: hapus file paket unduhan (tools tetap terpasang)
"$MM_DIR/bin/micromamba" clean -y -a >> "$LOG" 2>&1 || true
rm -f "$MM_DIR/micromamba.tar.bz2"

# Buat tools tersedia di setiap terminal, bahkan di luar VS Code
if ! grep -qs "brsp-env" "$HOME/.bashrc"; then
  {
    echo ''
    echo '# BRSP tools'
    echo "export PATH=\"$ENV_DIR/bin:\$PATH\""
    echo 'export JAVA_TOOL_OPTIONS="-Xlog:disable -Xlog:all=warning:stderr"'
  } >> "$HOME/.bashrc"
fi

# Cek apakah instalasi berhasil
export PATH="$ENV_DIR/bin:$PATH"
export JAVA_TOOL_OPTIONS="-Xlog:disable -Xlog:all=warning:stderr"
prokka --version
datasets --version
seqkit version
mafft --version
FastTree -expert 2>&1 | head -n 1
echo "Setup BRSP selesai. Buka terminal dan mulai dari week2/week2_annotation.sh"

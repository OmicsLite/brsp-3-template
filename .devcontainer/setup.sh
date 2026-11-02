#!/usr/bin/env bash
# Setup codespace BRSP: berjalan sekali, otomatis, saat codespace dibuat.
# Meng-install tools BRSP ke environment tersendiri (~/brsp-env):
#   Minggu 2: Prokka, NCBI Datasets   Minggu 3: seqkit, MAFFT, FastTree
# Log lengkap: ~/brsp-setup.log
#
# Kalau setup gagal, codespace TETAP terbuka. Jalankan ulang dengan:
#   bash .devcontainer/setup.sh
set -uo pipefail

ENV_DIR="$HOME/brsp-env"
LOG="$HOME/brsp-setup.log"
MM_DIR="$HOME/.micromamba"
MM="$MM_DIR/bin/micromamba"
export MAMBA_ROOT_PREFIX="$MM_DIR/root"

echo "Setup BRSP: meng-install tools bioinformatika (sekitar 2-5 menit)..."
echo "Log lengkap: $LOG"
echo "===== Setup BRSP dimulai: $(date) =====" >> "$LOG"

# Jalankan suatu langkah hingga 3 kali, untuk mengatasi gangguan unduhan sesaat
retry() {
  local n
  for n in 1 2 3; do
    "$@" >> "$LOG" 2>&1 && return 0
    [ "$n" = 3 ] && break
    echo "  Percobaan $n gagal, mencoba lagi..." | tee -a "$LOG"
    sleep 10
  done
  return 1
}

install_tools() {
  # zip/unzip dibutuhkan untuk membuka unduhan NCBI dan membungkus hasil
  if ! command -v unzip > /dev/null || ! command -v zip > /dev/null; then
    retry sudo apt-get update -qq || return 1
    retry sudo apt-get install -y -qq unzip zip || return 1
  fi

  # micromamba: installer conda yang kecil dan cepat (versi dikunci)
  if [ ! -x "$MM" ]; then
    mkdir -p "$MM_DIR"
    retry curl -sSL --fail -o "$MM_DIR/micromamba.tar.bz2" \
      "https://conda.anaconda.org/conda-forge/linux-64/micromamba-1.5.10-0.tar.bz2" || return 1
    tar -xjf "$MM_DIR/micromamba.tar.bz2" -C "$MM_DIR" bin/micromamba >> "$LOG" 2>&1 || return 1
    rm -f "$MM_DIR/micromamba.tar.bz2"
  fi

  # Tools BRSP. Kalau unduhan rusak, cache paket dikosongkan sebelum mencoba lagi.
  local n
  for n in 1 2 3; do
    if "$MM" create -y -q -p "$ENV_DIR" \
         -c conda-forge -c bioconda --strict-channel-priority \
         prokka=1.15.6 ncbi-datasets-cli seqkit mafft fasttree >> "$LOG" 2>&1; then
      break
    fi
    rm -rf "$ENV_DIR" "$MAMBA_ROOT_PREFIX/pkgs"
    if [ "$n" = 3 ]; then
      echo "  Instalasi tools percobaan $n gagal." | tee -a "$LOG"
      return 1
    fi
    echo "  Instalasi tools percobaan $n gagal, mencoba lagi..." | tee -a "$LOG"
    sleep 10
  done

  # Hemat ruang disk: hapus file paket unduhan (tools tetap terpasang)
  "$MM" clean -y -a >> "$LOG" 2>&1 || true
  return 0
}

if ! install_tools; then
  echo ""
  echo "============================================================"
  echo " SETUP BRSP GAGAL. Codespace tetap bisa dipakai."
  echo " Penyebabnya (baris terakhir log):"
  echo "------------------------------------------------------------"
  tail -n 15 "$LOG"
  echo "------------------------------------------------------------"
  echo " Coba lagi di terminal:   bash .devcontainer/setup.sh"
  echo " Masih gagal? Kirim isi ~/brsp-setup.log ke TA-mu."
  echo "============================================================"
  exit 0
fi

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

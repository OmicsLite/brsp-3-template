#!/usr/bin/env bash
# =============================================================================
#  BRSP Minggu 2: Anotasi Genom Bakteri dengan Prokka
#  OmicsLite · Bioinformatics Research Starter Program · versi Codespaces
# =============================================================================
#
#  CARA MEMAKAI FILE INI
#  - Buka terminal di codespace-mu: menu ☰ → Terminal → New Terminal.
#  - Salin SATU blok setiap kali (di antara garis putus-putus), tempel ke
#    terminal, tekan Enter, lalu tunggu sampai selesai sebelum lanjut ke blok
#    berikutnya.
#    Jalan pintas: blok baris yang ingin dijalankan, tekan Ctrl+Shift+P →
#    "Terminal: Run Selected Text in Active Terminal".
#  - Baris yang diawali tanda # adalah catatan untukmu. Ikut tertempel pun
#    tidak masalah.
#  - Bandingkan hasilmu dengan catatan "YANG SEHARUSNYA KAMU LIHAT".
#
#  Waktu yang dibutuhkan: sekitar 30 menit, sebagian besar menunggu Prokka.
# =============================================================================


# -----------------------------------------------------------------------------
# LANGKAH 1  Masuk ke folder Minggu 2 dan cek tools
# -----------------------------------------------------------------------------
# Jalankan blok ini setiap kali kamu mulai bekerja.

mkdir -p "$(git rev-parse --show-toplevel)/week2"
cd "$(git rev-parse --show-toplevel)/week2"
pwd
prokka --version
datasets --version

# YANG SEHARUSNYA KAMU LIHAT
#   /workspaces/<nama-repo-mu>/week2
#   prokka 1.15.6
#   datasets version: 18.x.x
#
# Muncul "command not found"? Buka terminal baru lalu coba lagi. Masih tidak
# ada? Cek log setup:  tail -n 20 ~/brsp-setup.log


# -----------------------------------------------------------------------------
# LANGKAH 2  Unduh genom contoh
# -----------------------------------------------------------------------------
# E. coli K-12 MG1655, aksesi GCF_000005845.2. Kita hanya mengunduh FASTA
# genomnya (--include genome), tanpa anotasi dari NCBI: menganotasi genom
# adalah tugas kita.

datasets download genome accession GCF_000005845.2 --include genome \
  --filename ecoli_k12.zip
unzip -o -q ecoli_k12.zip -d ecoli_download
cp ecoli_download/ncbi_dataset/data/GCF_000005845.2/*_genomic.fna ecoli_k12.fna
ls -lh ecoli_k12.fna

# YANG SEHARUSNYA KAMU LIHAT
#   File bernama ecoli_k12.fna, berukuran sekitar 4,5 MB.
#   File ini juga muncul di daftar file sebelah kiri, di dalam folder week2.
#
# CHECKPOINT: mengapa kita mengunduh genom TANPA anotasi dari NCBI?


# -----------------------------------------------------------------------------
# LANGKAH 3  Periksa input
# -----------------------------------------------------------------------------

# Ada berapa sekuens? (setiap sekuens diawali baris header '>')
grep -c ">" ecoli_k12.fna

# Baris header-nya
grep ">" ecoli_k12.fna

# Beberapa baris pertama DNA
head -n 4 ecoli_k12.fna

# Panjang genom: buang baris header dan pindah baris, lalu hitung hurufnya
grep -v ">" ecoli_k12.fna | tr -d '\n' | wc -c

# YANG SEHARUSNYA KAMU LIHAT
#   1
#   >NC_000913.3 Escherichia coli str. K-12 substr. MG1655, complete genome
#   ...
#   4641652
#
# Satu sekuens, sekitar 4,6 juta huruf, dan sama sekali tanpa label.
#
# CHECKPOINT: kalau ini genom draft, bagaimana angka pertama akan berbeda?


# -----------------------------------------------------------------------------
# LANGKAH 4  Jalankan Prokka  (sekitar 10–15 menit)
# -----------------------------------------------------------------------------
#   --outdir / --prefix   lokasi hasil dan nama file-file hasilnya
#   --kingdom Bacteria    pakai pengaturan untuk gen bakteri
#   --genus/--species/--strain   beri label hasil dengan nama organismenya
#   --locustag ECOLI      ID gen yang mudah dibaca, seperti ECOLI_00001
#   --cpus 2              pakai 2 inti prosesor yang dimiliki codespace-mu
#   --force               timpa folder hasil kalau kamu menjalankannya lagi
#
# Prokka menjalankan beberapa tool sekaligus: Prodigal mencari gen penyandi
# protein, barrnap mencari gen rRNA (termasuk 16S), Aragorn mencari gen tRNA,
# lalu BLAST dan HMMER membandingkan gen dengan database untuk menebak
# fungsinya.

prokka --outdir ecoli_k12 --prefix ecoli_k12 \
  --kingdom Bacteria --genus Escherichia --species coli --strain K-12 \
  --locustag ECOLI --cpus 2 --force \
  ecoli_k12.fna > prokka_run.log 2>&1
tail -n 3 prokka_run.log

# YANG SEHARUSNYA KAMU LIHAT
#   Baris-baris terakhir berisi pesan penutup, seperti "Share and enjoy!"
#   atau "Thank you, come again." Kalau ada ERROR, lihat bagian Troubleshooting
#   di bawah.
#
# Ingin memantau prosesnya? Buka terminal kedua (tombol + di panel terminal)
# lalu jalankan:   tail -f prokka_run.log      (Ctrl+C untuk berhenti memantau)
#
# Biarkan tab browser tetap terbuka selama Prokka berjalan. Codespace berhenti
# setelah 30 menit tanpa aktivitas, dan perintah yang sedang berjalan tidak
# selalu dihitung sebagai aktivitas.


# -----------------------------------------------------------------------------
# LANGKAH 5  Jelajahi hasilnya  (pelajaran 2.4)
# -----------------------------------------------------------------------------
#   .txt  ringkasan jumlah fitur          .gff  semua fitur beserta posisinya
#   .tsv  satu baris per fitur            .gbk  fitur + sekuens (GenBank)
#   .ffn  DNA setiap gen (Minggu 3!)      .faa  protein setiap gen
#   .log  semua yang dilakukan Prokka

ls -lh ecoli_k12/
cat ecoli_k12/ecoli_k12.txt
head -n 10 ecoli_k12/ecoli_k12.tsv

# YANG SEHARUSNYA KAMU LIHAT (di ringkasan; angkanya bisa sedikit berbeda)
#   contigs: 1
#   bases: 4641652
#   CDS: sekitar 4.300–4.500
#   rRNA: sekitar 22
#   tRNA: sekitar 85–90
#
# Tips: klik ecoli_k12/ecoli_k12.tsv di daftar file sebelah kiri untuk
# membukanya sebagai tabel berwarna.
#
# CHECKPOINT: kolom mana yang akan kamu pakai untuk menghitung gen rRNA?


# -----------------------------------------------------------------------------
# LANGKAH 6  Cari gen tertentu  (pelajaran 2.4)
# -----------------------------------------------------------------------------

# lacZ: beta-galaktosidase, dari operon lac
grep -w "lacZ" ecoli_k12/ecoli_k12.tsv

# Di mana letaknya? Kolom: sekuens, tipe, awal, akhir, untai (strand)
grep "gene=lacZ;" ecoli_k12/ecoli_k12.gff | cut -f1,3,4,5,7

# Kalau lacZ tidak ditemukan berdasarkan nama, cari berdasarkan produknya:
#   grep -i "beta-galactosidase" ecoli_k12/ecoli_k12.tsv

# 16S rRNA: gen yang akan kita pakai untuk membuat pohon di Minggu 3
grep "16S ribosomal RNA" ecoli_k12/ecoli_k12.tsv
grep -c "16S ribosomal RNA" ecoli_k12/ecoli_k12.tsv

# YANG SEHARUSNYA KAMU LIHAT
#   lacZ, sekitar 3.000 bp, produk Beta-galactosidase
#   7 salinan 16S rRNA, masing-masing sekitar 1.500 bp
#
# CHECKPOINT: di Minggu 3 kita hanya memakai satu salinan 16S per genom.
# Mengapa yang terpanjang?


# -----------------------------------------------------------------------------
# LANGKAH 7  Cek kewajaran anotasi  (pelajaran 2.5)
# -----------------------------------------------------------------------------
# Tiga uji: kepadatan gen (~1 gen per kb), persentase protein hipotetis,
# dan jumlah rRNA/tRNA dibandingkan dengan yang sudah diketahui untuk
# organisme ini.

P=ecoli_k12/ecoli_k12
LEN=$(awk -F': ' '$1=="bases"{print $2}' $P.txt)
CDS=$(awk -F': ' '$1=="CDS"{print $2}' $P.txt)
RRNA=$(awk -F': ' '$1=="rRNA"{print $2+0}' $P.txt)
TRNA=$(awk -F': ' '$1=="tRNA"{print $2+0}' $P.txt)
HYPO=$(awk -F'\t' '$2=="CDS" && $7=="hypothetical protein"{n++} END{print n+0}' $P.tsv)
S16=$(awk -F'\t' '$7=="16S ribosomal RNA"{n++} END{print n+0}' $P.tsv)
awk -v len="$LEN" -v cds="$CDS" -v hypo="$HYPO" -v rrna="${RRNA:-0}" \
    -v trna="${TRNA:-0}" -v s16="$S16" 'BEGIN{
  printf "Panjang genom:            %d bp\n", len
  printf "Gen penyandi protein:     %d\n", cds
  printf "Gen per kb:               %.2f   (harapan sekitar 0,9-1,0)\n", cds/(len/1000)
  printf "Protein hipotetis:        %d (%.0f%% dari CDS)\n", hypo, 100*hypo/cds
  printf "Gen rRNA:                 %d\n", rrna
  printf "Salinan 16S:              %d   (harapan 7 untuk E. coli)\n", s16
  printf "Gen tRNA:                 %d\n", trna
}'

# BANDINGKAN DENGAN NCBI
# Buka https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000005845.2/
# lalu cari bagian "Annotation details". Catat jumlah gen penyandi protein,
# rRNA, dan tRNA dari NCBI di samping hasilmu. Selisih beberapa persen saja
# berarti hasilmu bagus.
#
# CHECKPOINT: genom proyekmu nanti tidak punya "jawaban benar".
# Uji mana dari ketiga uji ini yang tetap bisa kamu jalankan?


# -----------------------------------------------------------------------------
# LANGKAH 8  Simpan pekerjaanmu ke GitHub
# -----------------------------------------------------------------------------
# File-mu tetap tersimpan di codespace, tetapi portofoliomu adalah repo
# GitHub-mu. File berukuran besar (genom yang diunduh, .gbk, dan lainnya)
# otomatis dilewati oleh file .gitignore.

cd "$(git rev-parse --show-toplevel)"
git add week2
git commit -m "Minggu 2: anotasi E. coli K-12 dengan Prokka"
git push
git status

# YANG SEHARUSNYA KAMU LIHAT
#   "Your branch is up to date with 'origin/main'"
#   Muat ulang halaman repo-mu di GitHub: folder week2 sekarang berisi hasilmu.
#
# Sudah selesai untuk hari ini? Hentikan codespace agar jam gratismu awet:
#   github.com/codespaces → ⋯ di samping codespace-mu → Stop codespace


# =============================================================================
#  TROUBLESHOOTING
# =============================================================================
#  "command not found: prokka"
#      Buka terminal baru. Masih tidak ada? Jalankan
#      tail -n 20 ~/brsp-setup.log  lalu kirim hasilnya ke TA-mu.
#
#  "fatal: not a git repository"
#      Kamu sedang di luar folder repo. Jalankan Langkah 1 lagi.
#
#  Unduhan datasets gagal atau macet
#      NCBI sedang sibuk atau koneksi terputus. Tunggu sebentar, lalu ulangi
#      Langkah 2.
#
#  "cp: ... _genomic.fna: No such file or directory"
#      Unduhan atau unzip belum selesai. Ulangi Langkah 2.
#
#  Log Prokka diakhiri dengan ERROR
#      Baca penyebabnya:  tail -n 20 prokka_run.log
#      Pastikan file input ada (ls -lh ecoli_k12.fna), lalu ulangi Langkah 4.
#
#  "Could not parse version" di log Prokka
#      Jalankan perintah ini, lalu ulangi Langkah 4:
#      export JAVA_TOOL_OPTIONS="-Xlog:disable -Xlog:all=warning:stderr"
#
#  Codespace berhenti saat Prokka sedang berjalan
#      Buka lagi dari github.com/codespaces, jalankan Langkah 1, lalu
#      Langkah 4 lagi.
#
#  Langkah 7 menampilkan "division by zero"
#      Prokka belum selesai, sehingga ringkasannya kosong. Cek Langkah 4 dulu.
#
#  git push meminta password atau ditolak
#      Hubungi TA-mu. Biasanya Codespaces mengurus ini secara otomatis.
#
#  Masih bingung? Tulis di grup WhatsApp dengan menyertakan: langkah yang
#  sedang dikerjakan, pesan error lengkap (salin-tempel), dan apa saja yang
#  sudah kamu coba.
# =============================================================================

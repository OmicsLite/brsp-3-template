#!/usr/bin/env bash
# =============================================================================
#  BRSP Minggu 2: Genome Annotation Bakteri dengan Prokka
#  OmicsLite · Bioinformatics Research Starter Program · versi Codespaces
# =============================================================================
#
#  CARA MENGGUNAKAN FILE INI
#  - Buka terminal di codespace-mu: menu ☰ → Terminal → New Terminal.
#  - Copy SATU blok setiap kali (di antara garis putus-putus), paste ke
#    terminal, tekan Enter, lalu tunggu sampai selesai sebelum lanjut ke blok
#    berikutnya.
#    Shortcut: blok baris yang ingin dijalankan, tekan Ctrl+Shift+P →
#    "Terminal: Run Selected Text in Active Terminal".
#  - Baris yang diawali tanda # adalah catatan (comment) untukmu. Ikut
#    ter-paste pun tidak masalah.
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
# LANGKAH 2  Download genome contoh
# -----------------------------------------------------------------------------
# E. coli K-12 MG1655, accession GCF_000005845.2. Kita hanya men-download
# genome FASTA-nya (--include genome), tanpa annotation dari NCBI:
# meng-annotate genome adalah tugas kita.

datasets download genome accession GCF_000005845.2 --include genome \
  --filename ecoli_k12.zip
unzip -o -q ecoli_k12.zip -d ecoli_download
cp ecoli_download/ncbi_dataset/data/GCF_000005845.2/*_genomic.fna ecoli_k12.fna
ls -lh ecoli_k12.fna

# YANG SEHARUSNYA KAMU LIHAT
#   File bernama ecoli_k12.fna, berukuran sekitar 4,5 MB.
#   File ini juga muncul di daftar file sebelah kiri, di dalam folder week2.
#
# CHECKPOINT: mengapa kita men-download genome TANPA annotation dari NCBI?


# -----------------------------------------------------------------------------
# LANGKAH 3  Periksa input
# -----------------------------------------------------------------------------

# Ada berapa sequence? (setiap sequence diawali header line '>')
grep -c ">" ecoli_k12.fna

# Header line-nya
grep ">" ecoli_k12.fna

# Beberapa baris pertama DNA
head -n 4 ecoli_k12.fna

# Genome length: buang header line dan pindah baris, lalu hitung base-nya
grep -v ">" ecoli_k12.fna | tr -d '\n' | wc -c

# YANG SEHARUSNYA KAMU LIHAT
#   1
#   >NC_000913.3 Escherichia coli str. K-12 substr. MG1655, complete genome
#   ...
#   4641652
#
# Satu sequence, sekitar 4,6 juta base, dan sama sekali tanpa label.
#
# CHECKPOINT: kalau ini draft genome, bagaimana angka pertama akan berbeda?


# -----------------------------------------------------------------------------
# LANGKAH 4  Jalankan Prokka  (sekitar 10–15 menit)
# -----------------------------------------------------------------------------
#   --outdir / --prefix   lokasi output dan nama file-file output-nya
#   --kingdom Bacteria    pakai pengaturan untuk bacterial gene
#   --genus/--species/--strain   beri label output dengan nama organismenya
#   --locustag ECOLI      gene ID yang mudah dibaca, seperti ECOLI_00001
#   --cpus 2              pakai 2 CPU core yang dimiliki codespace-mu
#   --force               timpa folder output kalau kamu menjalankannya lagi
#
# Prokka menjalankan beberapa tool sekaligus: Prodigal mencari protein-coding
# gene, barrnap mencari rRNA gene (termasuk 16S), Aragorn mencari tRNA gene,
# lalu BLAST dan HMMER membandingkan gene dengan database untuk memprediksi
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
# LANGKAH 5  Jelajahi output-nya
# -----------------------------------------------------------------------------
#   .txt  summary jumlah feature          .gff  semua feature beserta posisinya
#   .tsv  satu baris per feature          .gbk  feature + sequence (GenBank)
#   .ffn  DNA sequence setiap gene        .faa  protein sequence setiap gene
#         (dipakai di Minggu 3!)
#   .log  semua yang dilakukan Prokka

ls -lh ecoli_k12/
cat ecoli_k12/ecoli_k12.txt
head -n 10 ecoli_k12/ecoli_k12.tsv

# YANG SEHARUSNYA KAMU LIHAT (di summary; angkanya bisa sedikit berbeda)
#   contigs: 1
#   bases: 4641652
#   CDS: sekitar 4.300–4.500
#   rRNA: sekitar 22
#   tRNA: sekitar 85–90
#
# Tips: klik ecoli_k12/ecoli_k12.tsv di daftar file sebelah kiri untuk
# membukanya sebagai tabel berwarna.
#
# CHECKPOINT: kolom mana yang akan kamu pakai untuk menghitung rRNA gene?


# -----------------------------------------------------------------------------
# LANGKAH 6  Cari gene tertentu
# -----------------------------------------------------------------------------

# lacZ: beta-galactosidase, dari lac operon
grep -w "lacZ" ecoli_k12/ecoli_k12.tsv

# Di mana letaknya? Kolom: sequence, type, start, end, strand
grep "gene=lacZ;" ecoli_k12/ecoli_k12.gff | cut -f1,3,4,5,7

# Kalau lacZ tidak ditemukan berdasarkan nama, cari berdasarkan product-nya:
#   grep -i "beta-galactosidase" ecoli_k12/ecoli_k12.tsv

# 16S rRNA: gene yang akan kita pakai untuk membuat phylogenetic tree di
# Minggu 3
grep "16S ribosomal RNA" ecoli_k12/ecoli_k12.tsv
grep -c "16S ribosomal RNA" ecoli_k12/ecoli_k12.tsv

# YANG SEHARUSNYA KAMU LIHAT
#   lacZ, sekitar 3.000 bp, product Beta-galactosidase
#   7 copy 16S rRNA, masing-masing sekitar 1.500 bp
#
# CHECKPOINT: di Minggu 3 kita hanya memakai satu 16S copy per genome.
# Mengapa yang terpanjang?


# -----------------------------------------------------------------------------
# LANGKAH 7  Cek kewajaran annotation
# -----------------------------------------------------------------------------
# Tiga uji: gene density (~1 gene per kb), persentase hypothetical protein,
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
  printf "Genome length:            %d bp\n", len
  printf "Protein-coding genes:     %d\n", cds
  printf "Genes per kb:             %.2f   (harapan sekitar 0.9-1.0)\n", cds/(len/1000)
  printf "Hypothetical proteins:    %d (%.0f%% dari CDS)\n", hypo, 100*hypo/cds
  printf "rRNA genes:               %d\n", rrna
  printf "16S copies:               %d   (harapan 7 untuk E. coli)\n", s16
  printf "tRNA genes:               %d\n", trna
}'

# BANDINGKAN DENGAN NCBI
# Buka https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000005845.2/
# lalu cari bagian "Annotation details". Catat jumlah protein-coding genes,
# rRNA, dan tRNA dari NCBI di samping hasilmu. Selisih beberapa persen saja
# berarti hasilmu bagus.
#
# CHECKPOINT: genome proyekmu nanti tidak punya "jawaban benar".
# Uji mana dari ketiga uji ini yang tetap bisa kamu jalankan?


# -----------------------------------------------------------------------------
# LANGKAH 8  Simpan pekerjaanmu ke GitHub
# -----------------------------------------------------------------------------
# File-mu tetap tersimpan di codespace, tetapi portofoliomu adalah repo
# GitHub-mu. File berukuran besar (genome yang di-download, .gbk, dan
# lainnya) otomatis dilewati oleh file .gitignore.

cd "$(git rev-parse --show-toplevel)"
git add week2
git commit -m "Minggu 2: genome annotation E. coli K-12 dengan Prokka"
git push
git status

# YANG SEHARUSNYA KAMU LIHAT
#   "Your branch is up to date with 'origin/main'"
#   Refresh halaman repo-mu di GitHub: folder week2 sekarang berisi hasilmu.
#
# Sudah selesai untuk hari ini? Hentikan codespace agar jatah gratis kita awet:
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
#  Download datasets gagal atau macet
#      NCBI sedang sibuk atau koneksi terputus. Tunggu sebentar, lalu ulangi
#      Langkah 2.
#
#  "cp: ... _genomic.fna: No such file or directory"
#      Download atau unzip belum selesai. Ulangi Langkah 2.
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
#      Prokka belum selesai, sehingga summary-nya kosong. Cek Langkah 4 dulu.
#
#  git push meminta password atau ditolak
#      Hubungi TA-mu. Biasanya Codespaces mengurus ini secara otomatis.
#
#  Masih bingung? Tulis di grup WhatsApp dengan menyertakan: langkah yang
#  sedang dikerjakan, pesan error lengkap (copy-paste), dan apa saja yang
#  sudah kamu coba.
# =============================================================================

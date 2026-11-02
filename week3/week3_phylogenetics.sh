#!/usr/bin/env bash
# =============================================================================
#  BRSP Minggu 3: Membuat Pohon Filogenetik dari 16S rRNA
#  OmicsLite · Bioinformatics Research Starter Program · versi Codespaces
# =============================================================================
#
#  POSISI KITA DALAM PIPELINE
#    Genom → Anotasi (Minggu 2) → Ekstraksi 16S → Alignment → Pohon → iTOL
#                                 ▲ minggu ini mencakup semua tahap ini
#
#  PERTANYAANNYA
#    Apakah kelima bakteri ini mengelompok sesuai dengan taksonominya?
#
#    Escherichia coli K-12          genom Minggu 2-mu
#    Shigella flexneri 301          kerabat yang terkenal "mengejutkan"
#    Salmonella enterica LT2        kerabat dekat
#    Klebsiella pneumoniae HS11286  kerabat yang lebih jauh
#    Pseudomonas aeruginosa PAO1    OUTGROUP (dari ordo yang berbeda sama sekali)
#
#  Keempat kerabat ini sudah dianotasi dengan Prokka untukmu, memakai
#  pengaturan yang sama dengan Minggu 2. Sekuens gen mereka (.ffn) ada di
#  week3/data/.
#
#  CARA MEMAKAI FILE INI
#  - Salin SATU blok setiap kali ke terminal, tekan Enter, lalu tunggu.
#    Jalan pintas: blok baris → Ctrl+Shift+P → "Terminal: Run Selected Text
#    in Active Terminal".
#  - Bandingkan hasilmu dengan catatan "YANG SEHARUSNYA KAMU LIHAT".
#
#  Waktu yang dibutuhkan: sekitar 45 menit. Setiap langkah selesai dalam
#  hitungan detik.
# =============================================================================


# -----------------------------------------------------------------------------
# LANGKAH 1  Masuk ke folder Minggu 3 dan cek tools
# -----------------------------------------------------------------------------

mkdir -p "$(git rev-parse --show-toplevel)/week3"
cd "$(git rev-parse --show-toplevel)/week3"
pwd
seqkit version
mafft --version
FastTree -expert 2>&1 | head -n 1

# YANG SEHARUSNYA KAMU LIHAT
#   /workspaces/<nama-repo-mu>/week3
#   seqkit v2.x, v7.5xx untuk MAFFT, dan "FastTree 2.x"
#
# Muncul "command not found"? Codespace-mu dibuat sebelum tools Minggu 3
# ditambahkan. Tekan Ctrl+Shift+P → "Codespaces: Rebuild Container", tunggu
# sampai selesai, lalu mulai lagi dari Langkah 1.


# -----------------------------------------------------------------------------
# LANGKAH 2  Lihat data contoh
# -----------------------------------------------------------------------------
# File .ffn berisi sekuens DNA setiap gen yang ditemukan Prokka (Minggu 2,
# Langkah 5). File keempat kerabat dikompres (.gz); seqkit bisa membacanya
# langsung.

ls -lh data/

# Gen E. coli-mu sendiri dari Minggu 2:
ls -lh ../week2/ecoli_k12/ecoli_k12.ffn

# Ada berapa gen 16S rRNA di setiap genom?
for f in ../week2/ecoli_k12/ecoli_k12.ffn data/*.ffn.gz; do
  printf "%-45s %s\n" "$f" "$(seqkit grep -n -r -p '16S ribosomal RNA' "$f" | grep -c '>')"
done

# YANG SEHARUSNYA KAMU LIHAT
#   Empat file .ffn.gz di data/, ditambah ecoli_k12.ffn dari Minggu 2.
#   Beberapa salinan 16S per genom (E. coli punya 7). Bakteri memang sering
#   membawa beberapa salinan gen rRNA.
#
# Muncul "No such file" untuk ecoli_k12.ffn? Hasil Minggu 2-mu tidak ada di
# codespace ini. Ulangi Langkah 2 dan 4 dari Minggu 2, lalu kembali ke sini.


# -----------------------------------------------------------------------------
# LANGKAH 3  Ambil satu 16S per genom  (pelajaran 3.3)
# -----------------------------------------------------------------------------
# Pohon filogenetik butuh SATU sekuens yang bisa dibandingkan untuk setiap
# organisme. Kita pilih salinan 16S yang TERPANJANG (paling mungkin
# lengkap) lalu menamainya dengan nama spesies, sehingga pohonnya
# menampilkan "Escherichia_coli_K12", bukan "ECOLI_04012".
#
# Pertama untuk E. coli, satu perintah setiap kali, agar kamu bisa melihat
# fungsi masing-masing bagian:

# 3a. Cari semua gen 16S (-n: cari di seluruh header, -r: boleh cocok sebagian)
seqkit grep -n -r -p "16S ribosomal RNA" ../week2/ecoli_k12/ecoli_k12.ffn > ecoli_16S_all.fasta
seqkit stats ecoli_16S_all.fasta

# 3b. Urutkan dari yang terpanjang, ambil yang pertama, lalu ganti namanya
seqkit sort --quiet --by-length --reverse ecoli_16S_all.fasta \
  | seqkit head -n 1 \
  | seqkit replace -p '.+' -r 'Escherichia_coli_K12' > Escherichia_coli_K12_16S.fasta
seqkit stats Escherichia_coli_K12_16S.fasta
head -n 2 Escherichia_coli_K12_16S.fasta

# YANG SEHARUSNYA KAMU LIHAT
#   3a: 7 sekuens, masing-masing sekitar 1.500 bp
#   3b: 1 sekuens, sekitar 1.540 bp, dengan header >Escherichia_coli_K12

# Sekarang tiga langkah yang sama untuk keempat kerabat, dalam satu loop:
for pair in \
  "shigella_flexneri_301:Shigella_flexneri_301" \
  "salmonella_enterica_LT2:Salmonella_enterica_LT2" \
  "klebsiella_pneumoniae_HS11286:Klebsiella_pneumoniae_HS11286" \
  "pseudomonas_aeruginosa_PAO1:Pseudomonas_aeruginosa_PAO1"; do
  file="${pair%%:*}"; label="${pair##*:}"
  seqkit grep -n -r -p "16S ribosomal RNA" "data/$file.ffn.gz" \
    | seqkit sort --quiet --by-length --reverse \
    | seqkit head -n 1 \
    | seqkit replace -p '.+' -r "$label" > "${label}_16S.fasta"
done
ls *_16S.fasta

# CHECKPOINT: mengapa kita butuh tepat satu sekuens per organisme?


# -----------------------------------------------------------------------------
# LANGKAH 4  Gabungkan kelima sekuens 16S
# -----------------------------------------------------------------------------

cat Escherichia_coli_K12_16S.fasta Shigella_flexneri_301_16S.fasta \
    Salmonella_enterica_LT2_16S.fasta Klebsiella_pneumoniae_HS11286_16S.fasta \
    Pseudomonas_aeruginosa_PAO1_16S.fasta > all_16S.fasta
seqkit fx2tab -n -l all_16S.fasta

# YANG SEHARUSNYA KAMU LIHAT
#   Lima nama, masing-masing dengan panjang sekitar 1.500 bp.
#   Kalau ada baris yang hilang atau bernilai 0, 16S genom itu tidak
#   ditemukan: cek Langkah 3.


# -----------------------------------------------------------------------------
# LANGKAH 5  Alignment dengan MAFFT  (pelajaran 3.4)
# -----------------------------------------------------------------------------
# Alignment menjajarkan kelima sekuens sehingga setiap kolom berisi posisi
# yang "sama" pada setiap organisme, dengan menyisipkan gap (-) di tempat
# suatu sekuens punya basa tambahan atau kekurangan basa. Baru setelah itu
# kita bisa membandingkannya posisi demi posisi.

mafft --auto all_16S.fasta > aligned_16S.fasta 2> mafft.log
seqkit fx2tab -n -l aligned_16S.fasta

# YANG SEHARUSNYA KAMU LIHAT
#   Lima nama yang sama, sekarang SEMUANYA dengan panjang yang SAMA (sedikit
#   lebih panjang dari sebelumnya karena ada gap). Panjang yang sama berarti
#   alignment-nya valid.
#   MAFFT menulis hurufnya dalam huruf kecil (a, c, g, t). Itu normal.
#
# Lihat sepotong alignment, 60 kolom mulai dari posisi 1000:
seqkit subseq --quiet -r 1000:1060 aligned_16S.fasta | seqkit seq -w 0

# CHECKPOINT: pada potongan di atas, organisme mana yang paling berbeda dari
# yang lain? Apakah itu sesuai dengan perannya sebagai outgroup?


# -----------------------------------------------------------------------------
# LANGKAH 6  Buat pohon dengan FastTree  (pelajaran 3.5)
# -----------------------------------------------------------------------------
#   -nt    sekuensnya berupa nukleotida (DNA), bukan protein
#   -gtr   pakai model GTR untuk perubahan DNA dari waktu ke waktu
#
# FastTree menulis pohon dalam format Newick: kurung bersarang berisi nama
# dan panjang cabang, dengan nilai support (0-1) setelah setiap kurung tutup.

FastTree -nt -gtr aligned_16S.fasta > tree_16S.nwk 2> fasttree.log
cat tree_16S.nwk

# YANG SEHARUSNYA KAMU LIHAT
#   Satu baris berisi kurung, nama, dan angka, diakhiri ";". Contohnya:
#   (Escherichia_coli_K12:0.002,Shigella_flexneri_301:0.003,(Salmonella_...
#
#   Jangan khawatir kalau Pseudomonas tampak mengelompok dengan organisme
#   lain di sini. FastTree membuat pohon TANPA AKAR (unrooted): pohon ini
#   menunjukkan siapa yang dekat dengan siapa, tetapi tidak di mana pohon
#   bermula. Kamu akan memperbaikinya dengan me-root pohon pada outgroup di
#   Langkah 7.
#
# CHECKPOINT: angka tepat setelah ")" adalah nilai support. Apa artinya
# kalau suatu kelompok bernilai 0.4?


# -----------------------------------------------------------------------------
# LANGKAH 7  Visualisasikan di iTOL  (pelajaran 3.6)
# -----------------------------------------------------------------------------
# 1. Di daftar file sebelah kiri, buka week3, klik kanan tree_16S.nwk lalu
#    pilih Download.
# 2. Buka https://itol.embl.de lalu klik Upload. (Kamu bisa mengunggah tanpa
#    akun; dengan akun gratis kamu bisa menyimpan pohon.)
# 3. Unggah tree_16S.nwk.
# 4. ROOT POHONNYA: klik label Pseudomonas_aeruginosa_PAO1 →
#    Tree structure → Reroot the tree here.
# 5. Tampilkan nilai support: Control panel (kanan) → Advanced → Bootstrap /
#    metadata → Display → "Text".
# 6. Ekspor: Control panel → Export → PNG. Simpan sebagai tree_16S.png, lalu
#    unggah ke folder week3-mu (seret file ke folder di sebelah kiri).
#
# YANG SEHARUSNYA KAMU LIHAT (setelah di-root)
#   Pseudomonas sendirian di satu cabang, lalu Klebsiella, lalu Salmonella,
#   lalu E. coli dan Shigella berdampingan sebagai pasangan terdekat.


# -----------------------------------------------------------------------------
# LANGKAH 8  Interpretasikan pohonnya  (pelajaran 3.7)
# -----------------------------------------------------------------------------
# Tulis jawaban singkat di file bernama week3/interpretation.md:
#
#  1. Organisme mana yang paling dekat dengan E. coli K-12? Apakah itu sesuai
#     dengan dugaanmu berdasarkan namanya?
#  2. Secara nama, Shigella adalah genus yang berbeda, tetapi letaknya tepat
#     di samping (atau bahkan di dalam) E. coli. Cari tahu mengapa. Apakah
#     ini masalah pada pohonnya, atau pada namanya?
#  3. Lihat nilai support untuk kelompok E. coli + Shigella, dan panjang
#     cabang di antara keduanya. Apakah 16S bisa membedakan keduanya dengan
#     baik?
#  4. Mengapa kita membutuhkan Pseudomonas? Apa yang salah kalau tidak ada
#     outgroup?
#  5. Sebutkan satu keterbatasan membuat pohon dari satu gen saja.
#
# Buat file-nya lalu buka di editor:
touch interpretation.md
code interpretation.md 2> /dev/null || echo "Buka week3/interpretation.md dari daftar file di sebelah kiri."


# -----------------------------------------------------------------------------
# LANGKAH 9  Simpan pekerjaanmu ke GitHub
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"
git add week3
git commit -m "Minggu 3: pohon 16S E. coli dan kerabatnya"
git push
git status

# YANG SEHARUSNYA KAMU LIHAT
#   "Your branch is up to date with 'origin/main'"
#
# Sudah selesai untuk hari ini? Hentikan codespace-mu:
#   github.com/codespaces → ⋯ → Stop.


# =============================================================================
#  TROUBLESHOOTING
# =============================================================================
#  "command not found: seqkit" (atau mafft, FastTree)
#      Rebuild codespace-mu: Ctrl+Shift+P → "Codespaces: Rebuild Container".
#
#  "No such file" untuk data/*.ffn.gz
#      Repo-mu dibuat sebelum data contoh ditambahkan. Minta file-nya ke TA,
#      atau unduh dari repo template BRSP.
#
#  Ada file *_16S.fasta yang kosong
#      Pastikan nama file di loop Langkah 3 sama dengan nama file di data/.
#
#  Langkah 5: panjang sekuens berbeda-beda setelah MAFFT
#      MAFFT tidak selesai. Baca penyebabnya: tail mafft.log
#
#  Langkah 6: tree_16S.nwk kosong
#      Baca penyebabnya: tail fasttree.log
#      Biasanya alignment-nya kosong karena ada langkah sebelumnya yang gagal.
#
#  iTOL menolak file-nya
#      Pastikan yang kamu unggah adalah tree_16S.nwk, bukan file .fasta.
#
#  Masih bingung? Tulis di grup WhatsApp dengan menyertakan: langkah yang
#  sedang dikerjakan, pesan error lengkap (salin-tempel), dan apa saja yang
#  sudah kamu coba.
# =============================================================================

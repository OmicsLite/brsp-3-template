# My BRSP Project

**Bioinformatics Research Starter Program · OmicsLite**

Template Repositori ini adalah ruang kerja kita selama BRSP. Semua analisis dijalankan di **GitHub Codespaces**: komputer Linux di cloud yang terbuka langsung di browser, dengan semua tools bioinformatika sudah terpasang. Jadi kita tidak perlu meng-install apa pun di komputer kita sendiri.

## Memulai codespace

1. Di halaman repositori ini, klik tombol hijau **Code**.
2. Buka tab **Codespaces**, lalu klik **Create codespace on main**.
3. Tunggu proses setup selesai. **Pertama kali memakan waktu sekitar 3–6 menit** karena tools sedang di-install. Kita akan melihat log setup; biarkan sampai selesai.
4. Setelah VS Code muncul di browser, buka terminal: menu **☰ → Terminal → New Terminal**.
5. Cek apakah tools sudah siap dengan mengetik:

   ```bash
   prokka --version
   datasets --version
   ```

   Jika berhasil, hasilnya adalah `prokka 1.15.6` dan `datasets version: 18.x.x`.

Di waktu selanjutnya, buka **Code → Codespaces** lalu klik codespace yang sudah ada. Codespace akan terbuka lagi dengan tools dan file yang kita miliki masih lengkap.

## Weekly Task

| Minggu | Panduan |
|---|---|
| 2 · Genome Annotation| [`week2/week2_annotation.sh`](week2/week2_annotation.sh) |
| 3 · Phylogenetics | [`week3/week3_phylogenetics.sh`](week3/week3_phylogenetics.sh) |
| 4–5 · Project | *tersedia di Minggu 4* |

**Cara mengikuti panduan:** buka file panduan di editor, lalu salin satu blok perintah setiap kali ke terminal. Shortcut: blok baris yang ingin dijalankan, tekan **Ctrl+Shift+P** (Mac: **Cmd+Shift+P**), lalu pilih **"Terminal: Run Selected Text in Active Terminal"**.

## Menyimpan pekerjaan

File kita tetap tersimpan di codespace, tetapi **portofolio hasil BRSP kita adalah repositori GitHub ini**. Simpan ke GitHub setiap kali selesai bekerja:

```bash
git add .
git commit -m "Minggu 2: anotasi E. coli K-12"
git push
```

File berukuran besar (genom yang diunduh dan sebagian output Prokka) otomatis dilewati oleh file `.gitignore`.

## Gunakan Free Hour dengan bijak

GitHub memberi akun pribadi jatah jam Codespaces gratis setiap bulan. Jatah ini lebih dari cukup untuk BRSP, asalkan kamu:

- **Menghentikan codespace setiap selesai bekerja**: **Code → Codespaces → ⋯ → Stop codespace**. (Codespace juga berhenti sendiri setelah 30 menit tanpa aktivitas.)
- **Hanya memakai satu codespace** untuk BRSP. Hapus codespace lain di [github.com/codespaces](https://github.com/codespaces).

## Need help?

| Masalah | Solusi |
|---|---|
| `command not found: prokka` | Buka terminal **baru**. Masih tidak ada? Cek log setup: `tail -n 20 ~/brsp-setup.log` |
| Muncul pesan **SETUP BRSP GAGAL**, atau tools tidak ditemukan | Jalankan ulang setup di terminal: `bash .devcontainer/setup.sh` (sekitar 2–5 menit). Masih gagal? Kirim 20 baris terakhir dari `~/brsp-setup.log` ke TA |
| Codespace terbuka dalam **recovery mode** | Tekan **Ctrl+Shift+P** (Mac: **Cmd+Shift+P**) → **Codespaces: Rebuild Container** |
| Codespace tidak mau jalan, atau free hour habis | Hapus codespace lama di [github.com/codespaces](https://github.com/codespaces), lalu hubungi TA |

Untuk masalah lain, tulis di grup WhatsApp kelompok dengan menyertakan: langkah yang sedang dikerjakan, pesan error lengkap (salin-tempel), dan apa saja yang sudah kamu coba.

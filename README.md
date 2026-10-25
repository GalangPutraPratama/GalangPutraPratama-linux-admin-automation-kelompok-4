# Modul Otomasi Backup Direktori - Kelompok 4

## Tujuan
Shell script untuk mengotomatisasi backup direktori pada sistem Linux. Script membuat arsip `.tar.gz` beserta checksum SHA256, dilengkapi validasi input, pencatatan log, dan penanganan error.

## Use Case
Administrator perlu mem-backup direktori tertentu secara konsisten dengan arsip yang dapat diverifikasi. Script ini mengotomatisasi proses berikut:
1. Validasi direktori sumber dan tujuan
2. Pembuatan arsip terkompresi (tar.gz)
3. Pembuatan dan verifikasi checksum (SHA256)
4. Pencatatan log sebagai jejak audit

## Struktur Folder
```
├── config/
│   └── backup.conf.example
├── docs/
│   ├── hasil_test.txt
│   ├── log_sukses.txt
│   └── log_gagal.txt
├── src/
│   └── backup.sh
├── tests/
│   └── run_tests.sh
├── .gitignore
└── README.md
```

## Cara Menjalankan
```bash
# Pastikan script dapat dieksekusi
chmod +x src/backup.sh

# Jalankan backup
./src/backup.sh -s <direktori_sumber> -d <direktori_tujuan>

# Contoh
./src/backup.sh -s /home/user/data -d /home/user/backup
```

Parameter:
- `-s` : direktori yang akan di-backup (wajib)
- `-d` : direktori tujuan penyimpanan arsip (wajib)

## Konfigurasi
Salin `config/backup.conf.example` menjadi `config/backup.conf`, lalu sesuaikan path-nya. File `backup.conf` tidak di-upload ke repository (lihat `.gitignore`).

## Verifikasi Hasil
```bash
# Cek arsip dan checksum sudah terbentuk
ls /path/tujuan/backup_*.tar.gz
ls /path/tujuan/backup_*.tar.gz.sha256

# Verifikasi checksum
cd /path/tujuan && sha256sum -c backup_*.tar.gz.sha256
```

## Cleanup
```bash
# Hapus arsip backup tertentu beserta checksum-nya
rm /path/tujuan/backup_YYYYMMDD_HHMMSS.tar.gz
rm /path/tujuan/backup_YYYYMMDD_HHMMSS.tar.gz.sha256

# Hapus file log
rm /path/tujuan/backup_*.log
```

Selain itu, script menjalankan fungsi `cleanup` secara otomatis (melalui `trap`) untuk menghapus arsip setengah jadi jika proses terhenti.

## Rollback / Restore
```bash
# Ekstrak arsip ke direktori tujuan restore
mkdir -p /path/restore
tar -xzf /path/tujuan/backup_YYYYMMDD_HHMMSS.tar.gz -C /path/restore/
```

Cara yang sama juga tersedia melalui fungsi `restore_backup` di `src/backup.sh`.
<!-- TODO (Delia): setelah Galang selesai, tulis cara pemakaian restore_backup yang sebenarnya -->

## Exit Code
| Code | Arti |
|------|------|
| 0 | Backup berhasil |
| 1 | Argumen salah atau kurang |
| 2 | Direktori sumber tidak ada atau tidak dapat dibaca |
| 3 | Direktori tujuan tidak ada atau tidak dapat ditulis |
| 4 | Pembuatan arsip (tar) gagal |

## Hasil Test

Output lengkap ada di `docs/hasil_test.txt`.

- ✅ Test 1: Backup normal — PASS (exit code 0, arsip dan checksum berhasil dibuat)
- ✅ Test 2: Sumber tidak ada — PASS (exit code 2, script menolak direktori yang tidak ditemukan)
- ✅ Test 3: Argumen kurang — PASS (exit code 1, script menampilkan pesan penggunaan)

Hasil: **3/3 lulus**.

Contoh log sukses: `docs/log_sukses.txt`
Contoh log gagal: `docs/log_gagal.txt`

## Batasan / Fitur Belum Selesai
- Belum mendukung backup terjadwal (cron)
- Belum ada opsi retensi (penghapusan backup lama secara otomatis)
- Belum terintegrasi dengan layanan remote (SSH/SCP), direncanakan pada P12

## Kontribusi Anggota

| Anggota | Bagian | PR / Commit |
|---------|--------|-------------|
| Galang Putra Pratama | Script utama: `main`, `do_backup`, `verify_backup`, `restore_backup` | PR #1 · `9b38ca1` |
| Rania Zoya Irfan | Validasi input, error handling, logging, cleanup, ShellCheck | PR #2 · `5804cda` |
| Shelenia Violine Karo Karo | Test case (1 sukses, 2 gagal), bukti hasil test, interpretasi | PR #3 · `76fc4c2` |
| Delia Ayu Nandhita | README, config contoh, dokumentasi, submission | PR #4 · `1325938` |

## Lisensi
Tugas Proyek 2 - Praktikum Sistem Operasi

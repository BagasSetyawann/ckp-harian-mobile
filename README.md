# SI-CKP Mobile (Flutter)

Aplikasi **SI-CKP Mobile** dikhususkan bagi **Pegawai (Anggota)** untuk melakukan **input cepat kegiatan harian (CKP)** dan **unggah bukti dukung (Kamera, File, atau Link)** langsung dari smartphone, terhubung secara *real-time* ke server backend SI-CKP (`https://ckp-harian-backend.vercel.app/api`) dan **Portal Web Monitoring SI-CKP**.

---

## ✨ Fitur Utama Aplikasi Mobile
1. **Beranda Praktis Pegawai**
   - Indikator status pengisian CKP hari ini (Sudah Diisi / Belum Diisi).
   - Tombol pintas **Input Kegiatan CKP Hari Ini**.
   - Ringkasan capaian harian, total kegiatan bulan ini, jumlah bukti dukung, dan progres Rencana Kinerja (RK).
2. **Input CKP Harian 1-Langkah (`Input CKP`)**
   - Otomatis memilih Periode Aktif dan Tanggal Hari Ini.
   - Pilihan Rencana Kinerja (RK) otomatis mengisi satuan target.
   - Kalkulator persentase capaian otomatis (`Realisasi / Target × 100%`).
   - Langsung melampirkan **Foto Kamera**, **File Dokumen (PDF/JPG/PNG/XLS/DOC)**, dan **Link Bukti Dukung (Google Drive, dll.)** dalam satu layar yang sama.
3. **Riwayat Kegiatan & Bukti Dukung (`Riwayat`)**
   - Melihat riwayat kegiatan per periode beserta status verifikasi.
   - Menambah/menghapus bukti dukung serta mengedit/menghapus kegiatan yang belum diverifikasi.
4. **Monitoring RK & Nilai CKP (`RK & Nilai`)**
   - Memantau realisasi setiap Rencana Kinerja dan rincian Nilai CKP bulanan (Nilai PK + Nilai Perilaku).
5. **Profil & Pengaturan Server (`Profil`)**
   - Informasi pegawai, ganti password, serta pengaturan URL Server API pada halaman login.

---

## 🚀 Cara Menjalankan & Build APK Android

Pastikan **Flutter SDK** sudah terinstal di komputer Anda.

### 1. Inisialisasi Folder Platform Android/iOS/Web & Ambil Package
Buka terminal di dalam folder `mobile` ini, lalu jalankan:
```powershell
cd "c:\Users\ASUS\Downloads\CKP Harian\mobile"
flutter create . --project-name si_ckp_mobile
flutter pub get
```

> **Catatan Izin Internet Android (`android/app/src/main/AndroidManifest.xml`):**
> Pastikan di dalam file `android/app/src/main/AndroidManifest.xml` (di atas tag `<application>`) terdapat izin internet berikut agar aplikasi APK dapat menghubungi server Vercel:
> ```xml
> <uses-permission android:name="android.permission.INTERNET"/>
> ```

### 2. Menjalankan Aplikasi (Emulator / HP / Chrome)
```powershell
flutter run
```

### 3. Build File APK Android (Siap Install di HP)
```powershell
flutter build apk --release
```
File APK hasil build akan tersedia di:
`build/app/outputs/flutter-apk/app-release.apk`


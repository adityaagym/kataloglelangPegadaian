# Rencana Implementasi: Fitur Import Massal Excel ke SQLite di Flutter

Rencana ini disusun dengan format yang terstruktur agar mudah di-copy dan dijadikan **prompt** untuk LLM saat Anda ingin mengimplementasikannya nanti.

> [!WARNING]
> **Keterbatasan Format `.xls` di Flutter**
> Bahasa Dart (dan Flutter) tidak memiliki library *native* yang stabil untuk membaca format file `.xls` lawas (Excel 97-2003 biner). 
> **Solusi:** Sistem atau user harus melakukan "Save As" atau konversi file `.xls` tersebut menjadi format **`.xlsx`** atau **`.csv`** sebelum melakukan proses import ke dalam aplikasi mobile (tablet). Rencana ini berasumsi file sudah dalam format `.xlsx`.

---

## Prompt untuk LLM (Copy dari bawah ini)

**Tugas:**
Buatkan implementasi fitur Import Massal dari file Excel (`.xlsx`) ke database SQLite lokal di aplikasi Flutter. 

**Konteks Data yang Diambil:**
Data akan diambil dari sebuah file Excel yang berisi daftar barang. Field yang harus diekstrak dan disimpan ke database adalah:
1. `nomorAkad` (String)
2. `namaBarang` (String)
3. `jenisBarang` (String - contoh: Logam Mulia / Perhiasan Emas)
4. `berat` (Double - angka desimal)
5. `karat` (String/Integer - kadar emas)

**Spesifikasi dan Langkah-Langkah Implementasi yang Diinginkan:**

### 1. Dependencies
Harap gunakan package berikut (tambahkan di `pubspec.yaml`):
- `file_picker` (untuk memilih file dari storage tablet)
- `excel` (untuk membaca file `.xlsx`)
- `sqflite` dan `path` (untuk database SQLite)

### 2. Buat Data Model
Buatkan class model `LelangItem` yang merepresentasikan data di atas. Lengkapi dengan fungsi `toMap()` dan `fromMap()` untuk interaksi dengan SQLite.

### 3. Setup SQLite Database
Buatkan class `DatabaseHelper` dengan fungsi:
- Inisialisasi database.
- Membuat tabel `lelang_items` dengan kolom yang sesuai dengan model.
- Fungsi `insertMassal(List<LelangItem> items)` yang menggunakan metode `batch()` atau *transaction* dari `sqflite` agar proses insert ratusan/ribuan baris data berjalan efisien dan tidak membuat UI freeze.

### 4. Logika Ekstraksi File Excel
Buatkan service class `ExcelImportService` dengan alur:
1. Panggil `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'])`.
2. Baca bytes dari file yang dipilih.
3. Gunakan `Excel.decodeBytes()` untuk parsing file.
4. Lakukan iterasi baris (rows) pada sheet pertama.
5. (Asumsi row pertama adalah header) Skip index ke-0, dan lakukan mapping dari index kolom Excel ke properti model `LelangItem`.
6. Terapkan validasi tipe data sederhana (misal mengatasi `null` atau `String` yang harusnya `Double` pada kolom `berat`).
7. Kembalikan `List<LelangItem>`.

### 5. Integrasi ke UI (Pemanggilan)
Berikan contoh kode satu file UI (misal sebuah tombol di halaman Admin) yang memanggil proses ini dengan urutan:
- Tampilkan loading indicator (karena proses parse excel mungkin memakan waktu).
- Panggil `ExcelImportService` untuk mendapatkan List data.
- Panggil `DatabaseHelper.insertMassal()` untuk menyimpan ke SQLite.
- Tampilkan `SnackBar` sukses beserta jumlah baris yang berhasil di-import, lalu sembunyikan loading.

**Catatan Tambahan untuk LLM:**
- Harap gunakan *clean architecture* yang sederhana, pisahkan antara UI, model, dan database/service logic.
- Berikan penanganan error (try-catch) seperti jika file yang dipilih bukan `.xlsx` yang valid, atau format kolom tidak sesuai ekspektasi.

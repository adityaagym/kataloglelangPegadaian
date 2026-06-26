# Dokumentasi Simulasi Pembiayaan

## Ringkasan

Fitur simulasi pembiayaan membantu nasabah melihat estimasi uang muka dan angsuran untuk barang lelang. Aplikasi tetap bersifat offline first: semua data barang, nomor akad, konfigurasi pembiayaan, dan hasil simulasi berasal dari database lokal perangkat.

Simulasi ini bersifat estimasi. Nilai final tetap mengikuti verifikasi dan ketentuan outlet.

## Konsep Utama

- Data barang lelang diinput manual oleh admin cabang.
- Aplikasi tidak terhubung langsung dengan sistem Pegadaian.
- Perhitungan simulasi mengikuti pola rumus pada dokumen Excel referensi.
- Nomor akad/kredit boleh sama untuk beberapa barang.
- Barang dengan nomor akad/kredit yang sama dapat dihitung sebagai satu paket akad.

Contoh:

```text
Nomor akad BK 1234
- Cincin emas
- Kalung emas
```

Pada kasus ini, aplikasi dapat menampilkan simulasi untuk satu barang saja atau untuk seluruh barang dalam akad `BK 1234`.

## Rumus Simulasi

Parameter utama:

```text
STL        = Standar taksiran lelang
HDLE       = Harga dasar lelang emas
Kadar      = kadar/karat barang
Berat      = berat barang dalam gram
Loan ratio = rasio uang pinjaman, default 95%
Admin fee  = biaya administrasi
Tenor      = jangka waktu angsuran
Multiplier = faktor tenor dari Excel
```

Rumus:

```text
hargaJual = ROUNDUP((kadar / 24) * HDLE * berat, -4)
taksiran = STL * kadar / 24 * berat
uangPinjaman = ROUNDDOWN(taksiran * loanRatio, -5)
uangMuka = hargaJual - uangPinjaman + adminFee
angsuranBulanan = ROUNDUP((uangPinjaman * multiplier) / tenorBulan, -2)
```

Faktor tenor default:

```text
6 bulan  = 1.075
12 bulan = 1.150
18 bulan = 1.234
24 bulan = 1.312
36 bulan = 1.504
```

Contoh validasi dari Excel:

```text
uangPinjaman = Rp1.400.000
tenor = 6 bulan
multiplier = 1.075

angsuran = ROUNDUP((1.400.000 * 1.075) / 6, -2)
angsuran = Rp250.900 / bulan
```

## Alur Sisi Admin

### 1. Menginput Barang Lelang

Admin membuka halaman tambah/edit barang lalu mengisi data barang:

- Nomor akad/kredit.
- Nama barang.
- Kategori.
- Berat.
- Kadar/karat.
- Harga dasar lelang.
- Kondisi barang.
- Deskripsi.
- Foto barang.
- Status aktif/nonaktif.

Nomor akad/kredit tidak harus unik. Jika beberapa barang berasal dari akad yang sama, admin mengisi nomor akad yang sama pada semua barang tersebut.

### 2. Mengelola Barang Dengan Nomor Akad Sama

Pada daftar barang admin:

- Admin dapat melihat kolom nomor akad.
- Admin dapat mencari barang berdasarkan nama atau nomor akad.
- Barang dengan nomor akad yang sama dianggap sebagai bagian dari paket akad yang sama.

Contoh penggunaan:

```text
Cari: BK 1234
Hasil:
- Cincin emas
- Kalung emas
```

### 3. Mengatur Konfigurasi Pembiayaan

Konfigurasi pembiayaan tersimpan di database lokal. Nilai default mengikuti rumus Excel:

- STL: `502894`
- HDLE: `550000`
- Loan ratio: `95%`
- Tenor: `6, 12, 18, 24, 36 bulan`
- Multiplier tenor: sesuai tabel faktor tenor

Pada implementasi saat ini, core data dan perhitungan sudah mendukung konfigurasi tersebut. Halaman admin pembiayaan menampilkan aturan aktif dan faktor tenor. Pengembangan berikutnya dapat menambahkan input langsung untuk mengubah STL, HDLE, loan ratio, admin fee, dan multiplier tenor dari UI.

### 4. Dampak Input Admin ke Simulasi

Simulasi nasabah sangat bergantung pada data barang yang diinput admin. Data yang paling penting untuk barang emas:

- Kadar/karat.
- Berat gram.
- Harga dasar lelang.
- Nomor akad/kredit jika barang termasuk paket.

Jika kadar dan berat tersedia, aplikasi menghitung mengikuti rumus Excel. Jika data emas tidak lengkap, aplikasi tetap mencoba memakai harga barang sebagai fallback agar simulasi tidak gagal.

## Alur Sisi Nasabah

### 1. Melihat Detail Barang

Nasabah membuka detail barang dari katalog. Pada halaman detail, nasabah dapat melihat:

- Foto barang.
- Nama barang.
- Kategori.
- Berat.
- Kadar/karat.
- Kondisi.
- Nomor akad/kredit.
- Harga dasar lelang.
- Tombol simulasi pembiayaan.

### 2. Membuka Simulasi Pembiayaan

Jika fitur pembiayaan aktif, nasabah menekan tombol:

```text
Lihat Simulasi Pembiayaan
```

Aplikasi menampilkan estimasi:

- Angsuran per bulan.
- Harga jual.
- Uang pinjaman.
- Uang muka.
- Faktor tenor.
- Tenor.
- Mode simulasi.

### 3. Memilih Tenor

Nasabah dapat memilih tenor yang tersedia:

```text
6 bulan
12 bulan
18 bulan
24 bulan
36 bulan
```

Setiap perubahan tenor akan memperbarui estimasi angsuran.

### 4. Memilih Mode Simulasi

Jika barang memiliki nomor akad yang sama dengan barang lain, aplikasi menampilkan pilihan cakupan simulasi:

```text
Barang ini
Paket akad
```

Mode `Barang ini` menghitung simulasi hanya untuk barang yang sedang dibuka.

Mode `Paket akad` menghitung simulasi gabungan dari semua barang aktif yang memiliki nomor akad/kredit yang sama.

## Simulasi Paket Akad

Untuk paket akad, aplikasi tidak sekadar menjumlahkan angsuran tiap barang. Aplikasi menjumlahkan nilai barang/taksiran terlebih dahulu, lalu menghitung uang pinjaman dan angsuran pada level paket.

Pendekatan ini mengikuti pola perhitungan Excel dan menghindari selisih pembulatan.

Contoh:

```text
Akad BK 1234
- Cincin emas
- Kalung emas

Simulasi Paket Akad:
hargaJual = total harga jual cincin + kalung
taksiran = total taksiran cincin + kalung
uangPinjaman = pembulatan dari total taksiran * loanRatio
angsuran = pembulatan berdasarkan uangPinjaman paket
```

## Data Teknis

### Tabel Barang

Kolom penting pada `auction_items`:

```text
credit_number
name
category_id
weight_gram
karat
base_price
condition
description
is_active
created_at
```

`credit_number` boleh kosong dan boleh sama antar barang.

### Tabel Konfigurasi Pembiayaan

Kolom penting pada `financing_config`:

```text
stl_price
hdle_price
loan_ratio
admin_fee_flat
is_active
updated_at
```

### Tabel Tenor

Kolom penting pada `financing_tenors`:

```text
months
multiplier
is_active
```

## File Implementasi

- Model barang: `lib/models/auction_item.dart`
- Database lokal: `lib/database/database_helper.dart`
- Provider data: `lib/providers/app_provider.dart`
- Kalkulator simulasi: `lib/services/financing_calculator.dart`
- Form input barang admin: `lib/screens/admin/item_form_screen.dart`
- Daftar barang admin: `lib/screens/admin/item_list_screen.dart`
- Detail barang nasabah: `lib/screens/item_detail_screen.dart`
- Test kalkulator: `test/financing_calculator_test.dart`

## Batasan Saat Ini

- Simulasi adalah estimasi, bukan nilai final pembiayaan.
- Pengaturan STL, HDLE, loan ratio, dan multiplier sudah tersedia di struktur database, tetapi UI admin untuk mengedit semua parameter tersebut masih dapat dikembangkan lebih lanjut.
- Simulasi paling akurat untuk barang emas yang memiliki kadar dan berat lengkap.
- Aplikasi tetap offline, sehingga perubahan aturan dari pusat harus diinput manual oleh admin cabang jika diperlukan.

## Rekomendasi Pengembangan Berikutnya

- Tambahkan UI admin untuk mengubah STL, HDLE, loan ratio, admin fee, dan faktor tenor.
- Tambahkan preview simulasi di halaman admin pembiayaan.
- Tambahkan indikator visual di katalog untuk barang yang termasuk paket akad.
- Tambahkan fitur cetak atau bagikan ringkasan simulasi.
- Tambahkan disclaimer yang bisa diedit oleh admin cabang.

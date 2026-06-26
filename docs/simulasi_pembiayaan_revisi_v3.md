# Dokumentasi Simulasi Pembiayaan — Revisi v3.0

## Ringkasan Perubahan

Dokumen ini merupakan revisi lengkap dari simulasi pembiayaan berdasarkan:
1. Analisis mendalam dokumen Excel referensi (`KITIR LELANG BAKUNG 1.xlsx`)
2. Klarifikasi bisnis: **Tiga skema pembiayaan** (Tunai, KCA, KRASIDA)
3. Aplikasi offline-first untuk katalog barang lelang

**Perubahan utama v3.0:**
- Penambahan skema **KCA** (Kredit Cicilan Angsuran) — tempo 4 bulan
- Penambahan skema **Tunai** (pembelian langsung)
- Penjelasan detail perbedaan KCA vs KRASIDA
- Perhitungan bunga KCA (flat per bulan, tanpa angsuran rutin)
- UI/UX untuk pemilihan 3 skema

---

## 1. Konsep Utama

Aplikasi bersifat **offline-first**. Semua data — barang lelang, nomor akad, konfigurasi pembiayaan, dan hasil simulasi — berasal dari database lokal perangkat.

### 1.1 Tiga Skema Pembiayaan

Aplikasi menawarkan **tiga cara pembelian** barang lelang:

| Skema | Nama Lengkap | Cara Bayar | Jangka Waktu | Target Nasabah |
|-------|-------------|------------|--------------|----------------|
| **TUNAI** | Pembelian Tunai | Bayar penuh saat transaksi | Langsung | Nasabah dengan dana cukup |
| **KCA** | Kredit Cicilan Angsuran | Uang Muka + pelunasan bebas | **4 bulan** | Nasabah dengan DP, ingin pelunasan fleksibel |
| **KRASIDA** | Kredit Gadai Sistem Angsuran | Uang Muka + angsuran tetap | **6-36 bulan** | Nasabah ingin cicilan terstruktur |

### 1.2 Perbedaan KCA vs KRASIDA (Krusial)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KCA (Kredit Cicilan Angsuran)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  Harga Lelang: Rp 6.580.000                                                │
│  Uang Muka:    Rp 1.217.000   (DP / Down Payment)                          │
│  ─────────────────────────────────────                                      │
│  Sisa / Uang Pinjaman: Rp 5.363.000                                        │
│                                                                             │
│  ⚠️  TEMPO: 4 BULAN untuk melunasi sisa                                     │
│                                                                             │
│  • TIDAK ADA angsuran rutin per bulan                                       │
│  • Nasabah bayar bebas kapan saja selama 4 bulan                           │
│  • Bisa bayar sekaligus atau bertahap                                       │
│  • Bunga dihitung flat per bulan atas sisa pinjaman                        │
│                                                                             │
│  Contoh pelunasan:                                                          │
│  • Bulan 1: bayar Rp 2.000.000                                              │
│  • Bulan 3: bayar Rp 3.363.000 (lunas)                                      │
│                                                                             │
│  Bunga total = UP × bunga_flat × jumlah_bulan_tungakan                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        KRASIDA (Kredit Gadai Sistem Angsuran)              │
├─────────────────────────────────────────────────────────────────────────────┤
│  Harga Lelang: Rp 6.580.000                                                │
│  Uang Muka:    Rp 1.217.000   (DP — bisa lebih rendah dari KCA)            │
│  ─────────────────────────────────────                                      │
│  Uang Pinjaman: Rp 5.363.000                                               │
│                                                                             │
│  ✅ ANGSURAN TETAP per bulan:                                               │
│     • 6 bln : Rp 960.900 / bln                                              │
│     • 12 bln: Rp 514.000 / bln  ← paling umum                              │
│     • 18 bln: Rp 367.700 / bln                                              │
│     • 24 bln: Rp 293.200 / bln                                              │
│     • 36 bln: Rp 224.100 / bln                                              │
│                                                                             │
│  • Angsuran SAMA setiap bulan                                               │
│  • Nasabah tahu persis berapa bayar per bulan                               │
│  • Bunga flat, tidak berkurang meski saldo menurun                          │
│  • Jaminan: barang lelang yang dibeli                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Nomor Akad/Kredit

- Nomor akad/kredit **boleh sama** untuk beberapa barang.
- Barang dengan nomor akad yang sama dianggap **satu paket akad**.
- Simulasi dapat dihitung per barang atau per paket akad.

**Contoh Paket Akad:**

```text
Nomor akad: BK 1234
├── Cincin emas (kadar 21, 3.35g) — Harga Lelang: Rp 6.580.000
└── Kalung emas (kadar 22, 5.2g)  — Harga Lelang: Rp 2.370.000
```

---

## 2. Parameter & Konfigurasi

### 2.1 Tabel Konfigurasi (`financing_config`)

| Parameter | Key | Default | Keterangan |
|-----------|-----|---------|------------|
| **STL** | `stl_price` | `502894` | Standar Taksiran Lelang — harga per gram untuk kadar 24K |
| **HDLE** | `hdle_price` | `550000` | Harga Dasar Lelang Emas — harga per gram emas 24K |
| **Loan Ratio** | `loan_ratio` | `0.95` | Rasio uang pinjaman dari taksiran (95%) |
| **Admin Fee** | `admin_fee_flat` | `15000` | Biaya administrasi flat |
| **UM Persentase KCA** | `um_percentage_kca` | `0.192` | Persentase Uang Muka KCA (19.2%) |
| **UM Persentase KRASIDA** | `um_percentage_krasida` | `0.185` | Persentase Uang Muka KRASIDA (18.5%) |
| **Bunga KCA** | `bunga_kca` | `0.0125` | Bunga flat per bulan KCA (1.25%) |
| **Minimum UP KCA** | `minimum_up_kca` | `500000` | Minimum UP untuk KCA |
| **Minimum UP KRASIDA** | `minimum_up_krasida` | `500000` | Minimum UP untuk KRASIDA |
| **Tempo KCA** | `tempo_kca_bulan` | `4` | Jangka waktu KCA (bulan) |

### 2.2 Tabel Tenor KRASIDA (`financing_tenors`)

| Tenor (bulan) | Multiplier | Bunga Flat / Bulan | Sumber |
|---------------|------------|-------------------|--------|
| 6 | `1.075` | `1.25%` | `1.075 = 1 + 0.0125 × 6` |
| 12 | `1.150` | `1.25%` | `1.150 = 1 + 0.0125 × 12` |
| 18 | `1.234` | `1.30%` | `1.234 = 1 + 0.0130 × 18` |
| 24 | `1.312` | `1.30%` | `1.312 = 1 + 0.0130 × 24` |
| 36 | `1.504` | `1.40%` | `1.504 = 1 + 0.0140 × 36` |

> **Catatan**: Multiplier dan Bunga Flat adalah **dua representasi dari formula yang sama**:
> ```
> Angsuran = UP × multiplier / tenor = UP × (1 + r × tenor) / tenor
> ```

---

## 3. Rumus Perhitungan

### 3.1 Skema TUNAI

```dart
// PEMBELIAN TUNAI
// ─────────────────
// Harga Lelang = Input admin (manual)
// Total Bayar  = Harga Lelang
// Tidak ada bunga, tidak ada cicilan
```

### 3.2 Skema KCA (Kredit Cicilan Angsuran)

```dart
// INPUT: hargaLelang (diinput admin)
// INPUT: konfigurasi (bungaKCA, umPercentageKCA, tempoKCA, minimumUPKCA)

// Step 1: Hitung Uang Muka KCA
uangMukaKCA = ROUNDDOWN(hargaLelang * umPercentageKCA, -3)
// Contoh: 6.580.000 × 0.192 = 1.263.360 → 1.263.000

// Step 2: Hitung Uang Pinjaman KCA
uangPinjamanKCA = hargaLelang - uangMukaKCA
// Contoh: 6.580.000 - 1.263.000 = 5.317.000

// Step 3: Validasi Minimum UP
if (uangPinjamanKCA < minimumUPKCA) {
  return SimulasiResult(
    eligible: false,
    message: 'Barang ini hanya tersedia untuk pembelian tunai.',
  );
}

// Step 4: Hitung Bunga KCA (flat per bulan)
// Bunga dihitung atas sisa pinjaman setiap bulan
// Total bunga = UP × bungaKCA × tempoKCA
bungaTotalKCA = uangPinjamanKCA * bungaKCA * tempoKCA
// Contoh: 5.317.000 × 0.0125 × 4 = 265.850

// Step 5: Total yang harus dilunasi
totalPelunasanKCA = uangPinjamanKCA + bungaTotalKCA + adminFee
// Contoh: 5.317.000 + 265.850 + 15.000 = 5.597.850

// Step 6: Informasi tempo
// Nasabah punya TEMPO_KCA bulan untuk melunasi
// Bisa bayar kapan saja, tidak ada angsuran rutin
```

**Ringkasan KCA:**

| Item | Nilai | Keterangan |
|------|-------|------------|
| Harga Lelang | Rp 6.580.000 | Harga jual barang |
| Uang Muka | Rp 1.263.000 | DP 19.2% |
| Uang Pinjaman | Rp 5.317.000 | Sisa yang dipinjamkan |
| Tempo | 4 bulan | Waktu pelunasan |
| Bunga/bln | 1.25% | Flat atas sisa pinjaman |
| Bunga Total | Rp 265.850 | 5.317.000 × 1.25% × 4 |
| Admin Fee | Rp 15.000 | Biaya administrasi |
| **Total Pelunasan** | **Rp 5.597.850** | Sisa + bunga + admin |

### 3.3 Skema KRASIDA (Kredit Gadai Sistem Angsuran)

```dart
// INPUT: hargaLelang (diinput admin)
// INPUT: tenorBulan (dipilih nasabah: 6/12/18/24/36)
// INPUT: konfigurasi (multiplier/bunga, umPercentageKRASIDA, minimumUPKRASIDA)

// Step 1: Hitung Uang Muka KRASIDA
uangMuka = ROUNDDOWN(hargaLelang * umPercentageKRASIDA, -3)
// Contoh: 6.580.000 × 0.185 = 1.217.300 → 1.217.000

// Step 2: Hitung Uang Pinjaman
uangPinjaman = hargaLelang - uangMuka
// Contoh: 6.580.000 - 1.217.000 = 5.363.000

// Step 3: Validasi Minimum UP
if (uangPinjaman < minimumUPKRASIDA) {
  return SimulasiResult(
    eligible: false,
    message: 'Barang ini hanya tersedia untuk pembelian tunai.',
  );
}

// Step 4: Hitung Angsuran (Bunga Flat)
// Opsi A: Menggunakan Multiplier
angsuran = ROUNDUP((uangPinjaman * multiplier[tenor]) / tenor, -2)
// Contoh (tenor 12, mult 1.150): 5.363.000 × 1.150 / 12 = 513.958 → 514.000

// Opsi B: Menggunakan Bunga Flat (equivalen)
bungaPerBulan = bungaFlat[tenor]  // 0.0125 untuk 6-12 bln
angsuran = ROUNDUP((uangPinjaman * (1 + bungaPerBulan * tenor)) / tenor, -2)

// Step 5: Hitung Ringkasan
totalBayar = angsuran * tenor
bungaTotal = totalBayar - uangPinjaman
```

### 3.4 Perhitungan Taksiran (Informasi Transparansi)

```dart
// Taksiran dihitung untuk INFO saja, tidak mempengaruhi perhitungan lelang
taksiran = STL * (kadar / 24) * beratBersih
// Contoh (kadar 21, berat 3.35): 502.894 × 21/24 × 3.35 = 1.474.108
```

### 3.5 Aturan Pembulatan

| Nilai | Aturan | Kelipatan | Contoh |
|-------|--------|-----------|--------|
| Harga Jual Regular | ROUNDUP | 10.000 | 1.612.187 → 1.620.000 |
| Taksiran | Exact (tidak dibulatkan) | — | 1.474.108,04 |
| Uang Pinjaman Regular | ROUNDDOWN | 10.000 | 1.400.402 → 1.400.000 |
| Uang Muka KCA/KRASIDA | ROUNDDOWN | 1.000 | 1.217.300 → 1.217.000 |
| Angsuran KRASIDA | ROUNDUP | 100 | 513.958 → 514.000 |
| Bunga KCA | Exact | — | 265.850 |

> **Implementasi Dart:**
> ```dart
> int roundUp(int value, int factor) => ((value + factor - 1) ~/ factor) * factor;
> int roundDown(int value, int factor) => (value ~/ factor) * factor;
> ```

---

## 4. Alur Sisi Admin

### 4.1 Menginput Barang Lelang

Admin membuka halaman tambah/edit barang dan mengisi:

| Field | Tipe | Wajib | Keterangan |
|-------|------|-------|------------|
| Nomor akad/kredit | Text | Ya | Boleh sama antar barang |
| Nama nasabah | Text | Ya | Nama pemilik asal barang |
| Nama barang | Text | Ya | Deskripsi barang |
| Kategori | Dropdown | Ya | Cincin, Gelang, Kalung, LM, dll |
| Kadar/karat | Dropdown | Ya | 17, 18, 20, 21, 22, 24 |
| Berat kotor (g) | Number | Tidak | Berat sebelum diproses |
| Berat bersih (g) | Number | Ya | Berat setelah diproses |
| UP Asli | Number | Tidak | Uang Pinjaman asli (referensi) |
| **Harga lelang** | **Number** | **Ya** | **⭐ Harga jual barang di lelang (DISET MANUAL)** |
| Harga dasar | Number | Tidak | Referensi HDLE untuk info |
| Kondisi barang | Text | Tidak | Baik, Sedang, Rusak ringan |
| Deskripsi | Textarea | Tidak | Detail tambahan |
| Foto barang | Image | Tidak | Max 5 foto |
| Status | Toggle | Ya | Aktif / Nonaktif |
| Tanggal lelang | Date | Ya | Tanggal pelaksanaan lelang |

> **⭐ Field Krusial: Harga Lelang**
> - Diinput manual oleh admin (bukan auto-calculate)
> - Bisa lebih tinggi atau lebih rendah dari harga dasar
> - Menjadi dasar perhitungan **semua skema** (Tunai, KCA, KRASIDA)
> - Contoh dari Excel: UP Asli 5.530.000 → Harga Lelang 6.580.000 (markup ~19%)

### 4.2 Preview Simulasi Saat Input (3 Skema)

Saat admin mengisi **Harga Lelang**, tampilkan **preview simulasi real-time** untuk semua skema:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  PREVIEW SIMULASI PEMBIAYAAN — Rp 6.580.000                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  💵 TUNAI                                                                   │
│     Total Bayar: Rp 6.580.000                                              │
│     (Bayar penuh saat transaksi)                                           │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  💳 KCA (Kredit Cicilan Angsuran) — Tempo 4 Bulan                         │
│     Uang Muka:      Rp 1.263.000                                          │
│     Uang Pinjaman:  Rp 5.317.000                                          │
│     Bunga Total:    Rp 265.850                                            │
│     Admin Fee:      Rp 15.000                                             │
│     ─────────────────────────────────                                     │
│     Total Pelunasan: Rp 5.597.850                                         │
│     (Bayar bebas selama 4 bulan, tidak ada angsuran rutin)                 │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  📊 KRASIDA (Kredit Gadai Sistem Angsuran)                                  │
│     Uang Muka:      Rp 1.217.000                                          │
│     Uang Pinjaman:  Rp 5.363.000                                          │
│                                                                             │
│     ANGSURAN PER BULAN:                                                     │
│     • 6 bln : Rp 960.900  (total Rp 5.765.400)                            │
│     • 12 bln: Rp 514.000  (total Rp 6.168.000)  ← paling umum             │
│     • 18 bln: Rp 367.700  (total Rp 6.618.600)                            │
│     • 24 bln: Rp 293.200  (total Rp 7.036.800)                            │
│     • 36 bln: Rp 224.100  (total Rp 8.067.600)                            │
│                                                                             │
│  ⚠️ Minimum UP KCA: Rp 500.000  ✅ Eligible                              │
│  ⚠️ Minimum UP KRASIDA: Rp 500.000  ✅ Eligible                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Mengelola Barang Dengan Nomor Akad Sama

Pada daftar barang admin:

- Kolom "Nomor Akad" ditampilkan secara jelas
- Filter: "Tampilkan Paket Akad" — grup barang dengan nomor akad sama
- Search: Cari berdasarkan nomor akad atau nama barang
- Indikator visual: Icon "📦" untuk barang yang termasuk paket

### 4.4 Mengatur Konfigurasi Pembiayaan

Menu **Pengaturan > Konfigurasi Pembiayaan**:

| Parameter | Input | Default | Range |
|-----------|-------|---------|-------|
| STL | Number | 502894 | > 0 |
| HDLE | Number | 550000 | > 0 |
| Loan Ratio | Percentage | 95% | 50% - 100% |
| UM Persentase KCA | Percentage | 19.2% | 10% - 30% |
| UM Persentase KRASIDA | Percentage | 18.5% | 10% - 30% |
| Bunga KCA per Bulan | Percentage | 1.25% | 0.5% - 5% |
| Tempo KCA (bulan) | Number | 4 | 1 - 12 |
| Admin Fee | Number | 15000 | ≥ 0 |
| Minimum UP KCA | Number | 500000 | > 0 |
| Minimum UP KRASIDA | Number | 500000 | > 0 |
| Bunga KRASIDA 6-12 bln | Percentage | 1.25% | 0.5% - 5% |
| Bunga KRASIDA 18-24 bln | Percentage | 1.30% | 0.5% - 5% |
| Bunga KRASIDA 36 bln | Percentage | 1.40% | 0.5% - 5% |

> **Impact Preview**: Saat admin mengubah konfigurasi, tampilkan preview dampaknya pada contoh barang.

---

## 5. Alur Sisi Nasabah

### 5.1 Melihat Katalog Barang Lelang

```
┌─────────────────────────────────────────┐
│ ≡  Katalog Lelang              [🔍] [⚙️]│
├─────────────────────────────────────────┤
│ [Semua ▼] [Kadar ▼] [Harga ▼] [Berat▼]│
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ [📷]                                │ │
│ │ 1 CINCIN — Kadar 22K — 13.4g       │ │
│ │                                     │ │
│ │ 💰 Rp 6.580.000                     │ │
│ │ 📦 Paket BK 1234 (2 barang)         │ │
│ │ 💳 3 Skema Tersedia                 │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ [📷]                                │ │
│ │ 1 GELANG — Kadar 21K — 6.7g        │ │
│ │                                     │ │
│ │ 💰 Rp 3.140.000                     │ │
│ │ 💵 Tunai / 💳 KCA / 📊 KRASIDA      │ │
│ └─────────────────────────────────────┘ │
│                                         │
│  [🏠]      [📋]      [ℹ️]               │
└─────────────────────────────────────────┘
```

### 5.2 Detail Barang + Simulasi Pembiayaan (3 Skema)

```
┌─────────────────────────────────────────┐
│ ←  1 CINCIN — Kadar 22K                 │
├─────────────────────────────────────────┤
│  [📷 Carousel Foto Barang]              │
│  ○ ○ ● ○ ○                              │
│                                         │
│  No Akad: BK 1234                       │
│  Nasabah: AFRIYANTI                     │
│  Kadar: 22K | Berat: 13.4g              │
│  📋 Ada Surat Emas                      │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  💰 HARGA LELANG                │    │
│  │     Rp 6.580.000                │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  PILIH CARA PEMBELIAN:                  │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │  TUNAI │ │  KCA   │ │KRASIDA │      │
│  │  Rp6.5M│ │ 4 bln  │ │Cicilan │      │
│  │   🔘   │ │        │ │        │      │
│  └────────┘ └────────┘ └────────┘      │
│                                         │
│  ╔═════════════════════════════════════╗│
│  ║  💵 PEMBELIAN TUNAI                 ║│
│  ╠═════════════════════════════════════╣│
│  ║  Total Bayar: Rp 6.580.000          ║│
│  ║                                     ║│
│  ║  Bayar penuh saat transaksi.        ║│
│  ║  Tidak ada bunga atau cicilan.      ║│
│  ╚═════════════════════════════════════╝│
│                                         │
│  [ 📞 HUBUNGI PEGADAI ]                 │
└─────────────────────────────────────────┘
```

**Jika KCA dipilih:**

```
│  ╔═════════════════════════════════════╗│
│  ║  💳 KCA — Kredit Cicilan Angsuran   ║│
│  ╠═════════════════════════════════════╣│
│  ║  Harga Lelang:      Rp 6.580.000    ║│
│  ║  Uang Muka (19.2%): Rp 1.263.000    ║│
│  ║  ─────────────────────────────────  ║│
│  ║  Uang Pinjaman:     Rp 5.317.000    ║│
│  ║                                     ║│
│  ║  ⏱️ TEMPO: 4 BULAN                  ║│
│  ║                                     ║│
│  ║  Anda punya waktu 4 bulan untuk     ║│
│  ║  melunasi sisa pinjaman.            ║│
│  ║                                     ║│
│  ║  • TIDAK ADA angsuran rutin         ║│
│  ║  • Bayar kapan saja, bebas jumlah   ║│
│  ║  • Bunga 1.25% flat per bulan      ║│
│  ║                                     ║│
│  ║  Rincian:                           ║│
│  ║  • Bunga Total:    Rp 265.850       ║│
│  ║  • Admin Fee:      Rp 15.000        ║│
│  ║  ─────────────────────────────────  ║│
│  ║  TOTAL PELUNASAN:  Rp 5.597.850     ║│
│  ╚═════════════════════════════════════╝│
│                                         │
│  [ 📞 HUBUNGI PEGADAI ]                 │
│  [ 💾 SIMPAN SIMULASI ]                 │
│                                         │
│  ⚠️ Simulasi ini bersifat estimasi.     │
│     Nilai final mengikuti verifikasi    │
│     dan ketentuan outlet.               │
```

**Jika KRASIDA dipilih:**

```
│  ╔═════════════════════════════════════╗│
│  ║  📊 KRASIDA — Kredit Gadai Sistem   ║│
│  ║       Angsuran                      ║│
│  ╠═════════════════════════════════════╣│
│  ║  Harga Lelang:      Rp 6.580.000    ║│
│  ║  Uang Muka (18.5%): Rp 1.217.000   ║│
│  ║  ─────────────────────────────────  ║│
│  ║  Uang Pinjaman:     Rp 5.363.000   ║│
│  ╚═════════════════════════════════════╝│
│                                         │
│  PILIH TENOR:                           │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │ 6  │ │►12 │ │ 18 │ │ 24 │ │ 36 │   │
│  │bln │ │bln │ │bln │ │bln │ │bln │   │
│  └────┘ └────┘ └────┘ └────┘ └────┘   │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │    ANGSURAN PER BULAN           │    │
│  │                                 │    │
│  │       Rp 514.000                │    │  ← Very Large, Gold
│  │                                 │    │
│  │    / bulan × 12 bulan           │    │
│  │    Bunga 1.25% flat per bulan   │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Detail Pembayaran:                     │
│  • Total Bayar:     Rp 6.168.000        │
│  • Bunga Total:     Rp 805.000          │
│  • Uang Muka:      Rp 1.217.000         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  📊 PERBANDINGAN SEMUA TENOR  │    │
│  │  ┌────┬────────┬────────┬──────┐│    │
│  │  │Bln │Angsuran│ Total  │Bunga ││    │
│  │  ├────┼────────┼────────┼──────┤│    │
│  │  │ 6  │960.900 │5.765.400│402.400││   │
│  │  │►12 │514.000 │6.168.000│805.000││   │  ← selected
│  │  │ 18 │367.700 │6.618.600│1.255.600││ │
│  │  │ 24 │293.200 │7.036.800│1.673.800││ │
│  │  │ 36 │224.100 │8.067.600│2.704.600││ │
│  │  └────┴────────┴────────┴──────┘│    │
│  └─────────────────────────────────┘    │
│                                         │
│  [ 📞 HUBUNGI PEGADAI ]                 │
│  [ 💾 SIMPAN SIMULASI ]                 │
│                                         │
│  ⚠️ Simulasi ini bersifat estimasi.     │
│     Nilai final mengikuti verifikasi    │
│     dan ketentuan outlet.               │
```

### 5.3 Mode Simulasi Paket Akad

Jika barang memiliki nomor akad yang sama dengan barang lain:

```
┌─────────────────────────────────────────┐
│  MODE SIMULASI:                         │
│  ┌────────────┐  ┌────────────┐        │
│  │ Barang ini │  │ Paket Akad │        │
│  │   (🔘)     │  │   (⚪)     │        │
│  └────────────┘  └────────────┘        │
│                                         │
│  Barang dalam paket BK 1234:            │
│  • Cincin emas (22K, 13.4g) — Rp 6.580.000│
│  • Kalung emas (22K, 5.2g)  — Rp 2.370.000│
│                                         │
│  Total Harga Lelang: Rp 8.950.000       │
│                                         │
│  💵 TUNAI: Rp 8.950.000                 │
│                                         │
│  💳 KCA:                                │
│     UM: Rp 1.718.000 | UP: Rp 7.232.000 │
│     Tempo 4 bln | Total: Rp 7.629.600   │
│                                         │
│  📊 KRASIDA (12 bln):                   │
│     UM: Rp 1.655.000 | UP: Rp 7.295.000 │
│     Angsuran: Rp 698.900 / bulan        │
└─────────────────────────────────────────┘
```

---

## 6. Simulasi Paket Akad

### 6.1 Perhitungan Level Paket

Untuk menghindari selisih pembulatan, perhitungan dilakukan **di level paket**:

```dart
// Ambil semua barang aktif dengan nomor akad yang sama
List<AuctionItem> paket = await db.getBarangByNomorAkad(creditNumber);

// ─── TUNAI ───
int totalHargaTunai = paket.fold(0, (sum, b) => sum + b.hargaLelang);

// ─── KCA ───
int totalHargaKCA = paket.fold(0, (sum, b) => sum + b.hargaLelang);
int totalUMKCA = roundDown((totalHargaKCA * config.umPercentageKca).round(), 1000);
int totalUPKCA = totalHargaKCA - totalUMKCA;
int bungaTotalKCA = (totalUPKCA * config.bungaKca * config.tempoKca).round();
int totalPelunasanKCA = totalUPKCA + bungaTotalKCA + config.adminFee;

// ─── KRASIDA ───
int totalHargaKrasida = paket.fold(0, (sum, b) => sum + b.hargaLelang);
int totalUMKrasida = roundDown((totalHargaKrasida * config.umPercentageKrasida).round(), 1000);
int totalUPKrasida = totalHargaKrasida - totalUMKrasida;
int angsuranKrasida = roundUp((totalUPKrasida * multiplier[tenor]) / tenor, 100);
```

### 6.2 Contoh Perhitungan Paket

```text
Akad: BK 1234
├── Cincin emas (22K, 13.4g) — Harga Lelang: Rp 6.580.000
└── Kalung emas (22K, 5.2g)  — Harga Lelang: Rp 2.370.000

═══════════════════════════════════════════════════════════════
TUNAI
Total: Rp 8.950.000

═══════════════════════════════════════════════════════════════
KCA
Total Harga Lelang = 6.580.000 + 2.370.000 = 8.950.000
Total Uang Muka    = 8.950.000 × 0.192 = 1.718.400 → 1.718.000
Total Uang Pinjaman = 8.950.000 - 1.718.000 = 7.232.000
Bunga Total        = 7.232.000 × 0.0125 × 4 = 361.600
Admin Fee          = 15.000
Total Pelunasan    = 7.232.000 + 361.600 + 15.000 = 7.608.600

═══════════════════════════════════════════════════════════════
KRASIDA (12 bln)
Total Harga Lelang = 8.950.000
Total Uang Muka    = 8.950.000 × 0.185 = 1.655.750 → 1.655.000
Total Uang Pinjaman = 8.950.000 - 1.655.000 = 7.295.000
Angsuran           = 7.295.000 × 1.150 / 12 = 698.854 → 698.900
Total Bayar        = 698.900 × 12 = 8.386.800
Bunga Total        = 8.386.800 - 7.295.000 = 1.091.800
```

> **Kenapa perhitungan paket lebih akurat?** Karena pembulatan dilakukan SEKALI di level paket, bukan per barang lalu dijumlahkan.

---

## 7. Implementasi Teknis

### 7.1 Model Data

```dart
// ============================================
// MODEL: Konfigurasi Pembiayaan
// ============================================
class FinancingConfig {
  final int id;
  final int stlPrice;              // Standar Taksiran Lelang per gram (24K)
  final int hdlePrice;             // Harga Dasar Lelang Emas per gram (24K)
  final double loanRatio;          // Rasio pinjaman (0.95 = 95%)
  final int adminFeeFlat;          // Biaya admin flat
  final double umPercentageKca;    // Persentase Uang Muka KCA (0.192 = 19.2%)
  final double umPercentageKrasida;// Persentase Uang Muka KRASIDA (0.185 = 18.5%)
  final double bungaKca;           // Bunga flat per bulan KCA (0.0125 = 1.25%)
  final int tempoKca;              // Tempo KCA dalam bulan (4)
  final int minimumUpKca;          // Minimum UP untuk KCA
  final int minimumUpKrasida;      // Minimum UP untuk KRASIDA
  final bool isActive;
  final DateTime updatedAt;

  FinancingConfig({
    required this.id,
    required this.stlPrice,
    required this.hdlePrice,
    required this.loanRatio,
    required this.adminFeeFlat,
    required this.umPercentageKca,
    required this.umPercentageKrasida,
    required this.bungaKca,
    required this.tempoKca,
    required this.minimumUpKca,
    required this.minimumUpKrasida,
    this.isActive = true,
    required this.updatedAt,
  });

  factory FinancingConfig.fromMap(Map<String, dynamic> map) {
    return FinancingConfig(
      id: map['id'] as int,
      stlPrice: map['stl_price'] as int,
      hdlePrice: map['hdle_price'] as int,
      loanRatio: (map['loan_ratio'] as num).toDouble(),
      adminFeeFlat: map['admin_fee_flat'] as int,
      umPercentageKca: (map['um_percentage_kca'] as num).toDouble(),
      umPercentageKrasida: (map['um_percentage_krasida'] as num).toDouble(),
      bungaKca: (map['bunga_kca'] as num).toDouble(),
      tempoKca: map['tempo_kca'] as int,
      minimumUpKca: map['minimum_up_kca'] as int,
      minimumUpKrasida: map['minimum_up_krasida'] as int,
      isActive: map['is_active'] == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

// ============================================
// MODEL: Tenor KRASIDA
// ============================================
class FinancingTenor {
  final int id;
  final int months;              // 6, 12, 18, 24, 36
  final double multiplier;      // 1.075, 1.150, 1.234, 1.312, 1.504
  final double bungaFlat;       // 0.0125, 0.0125, 0.0130, 0.0130, 0.0140
  final bool isActive;

  FinancingTenor({
    required this.id,
    required this.months,
    required this.multiplier,
    required this.bungaFlat,
    this.isActive = true,
  });

  String get bungaFlatPercent => '${(bungaFlat * 100).toStringAsFixed(2)}%';

  factory FinancingTenor.fromMap(Map<String, dynamic> map) {
    return FinancingTenor(
      id: map['id'] as int,
      months: map['months'] as int,
      multiplier: (map['multiplier'] as num).toDouble(),
      bungaFlat: (map['bunga_flat'] as num).toDouble(),
      isActive: map['is_active'] == 1,
    );
  }
}

// ============================================
// MODEL: Barang Lelang
// ============================================
class AuctionItem {
  final int? id;
  final String creditNumber;
  final String namaNasabah;
  final String namaBarang;
  final String kategori;
  final int kadar;
  final double? beratKotor;
  final double beratBersih;
  final int? upAsli;
  final int hargaLelang;
  final int? hargaDasar;
  final String? kondisi;
  final String? deskripsi;
  final List<String>? fotoPaths;
  final bool isActive;
  final DateTime tanggalLelang;
  final DateTime? tanggalTerjual;
  final int? hargaTerjual;
  final DateTime createdAt;

  AuctionItem({
    this.id,
    required this.creditNumber,
    required this.namaNasabah,
    required this.namaBarang,
    required this.kategori,
    required this.kadar,
    this.beratKotor,
    required this.beratBersih,
    this.upAsli,
    required this.hargaLelang,
    this.hargaDasar,
    this.kondisi,
    this.deskripsi,
    this.fotoPaths,
    this.isActive = true,
    required this.tanggalLelang,
    this.tanggalTerjual,
    this.hargaTerjual,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get status {
    if (tanggalTerjual != null) return 'terjual';
    if (!isActive) return 'nonaktif';
    if (tanggalLelang.isBefore(DateTime.now())) return 'expired';
    return 'tersedia';
  }

  bool get isPartOfPackage => creditNumber.isNotEmpty;

  factory AuctionItem.fromMap(Map<String, dynamic> map) {
    return AuctionItem(
      id: map['id'] as int?,
      creditNumber: map['credit_number'] as String,
      namaNasabah: map['nama_nasabah'] as String,
      namaBarang: map['nama_barang'] as String,
      kategori: map['kategori'] as String,
      kadar: map['kadar'] as int,
      beratKotor: map['berat_kotor'] != null ? (map['berat_kotor'] as num).toDouble() : null,
      beratBersih: (map['berat_bersih'] as num).toDouble(),
      upAsli: map['up_asli'] as int?,
      hargaLelang: map['harga_lelang'] as int,
      hargaDasar: map['harga_dasar'] as int?,
      kondisi: map['kondisi'] as String?,
      deskripsi: map['deskripsi'] as String?,
      fotoPaths: map['foto_paths'] != null
          ? (map['foto_paths'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : null,
      isActive: map['is_active'] == 1,
      tanggalLelang: DateTime.parse(map['tanggal_lelang'] as String),
      tanggalTerjual: map['tanggal_terjual'] != null
          ? DateTime.parse(map['tanggal_terjual'] as String)
          : null,
      hargaTerjual: map['harga_terjual'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'credit_number': creditNumber,
      'nama_nasabah': namaNasabah,
      'nama_barang': namaBarang,
      'kategori': kategori,
      'kadar': kadar,
      'berat_kotor': beratKotor,
      'berat_bersih': beratBersih,
      'up_asli': upAsli,
      'harga_lelang': hargaLelang,
      'harga_dasar': hargaDasar,
      'kondisi': kondisi,
      'deskripsi': deskripsi,
      'foto_paths': fotoPaths?.join(','),
      'is_active': isActive ? 1 : 0,
      'tanggal_lelang': tanggalLelang.toIso8601String(),
      'tanggal_terjual': tanggalTerjual?.toIso8601String(),
      'harga_terjual': hargaTerjual,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ============================================
// MODEL: Hasil Simulasi (Generic untuk 3 skema)
// ============================================
class SimulasiResult {
  final SkemaType skema;           // tunai, kca, krasida
  final int hargaLelang;
  final int? uangMuka;
  final int? uangPinjaman;
  final bool eligible;
  final String? message;

  // KCA specific
  final int? tempoKca;
  final int? bungaTotalKca;
  final int? adminFee;
  final int? totalPelunasanKca;

  // KRASIDA specific
  final int? tenor;
  final double? bungaPerBulan;
  final int? angsuranPerBulan;
  final int? totalBayar;
  final int? bungaTotalKrasida;
  final List<SimulasiTenor>? perbandinganTenor;

  SimulasiResult({
    required this.skema,
    required this.hargaLelang,
    this.uangMuka,
    this.uangPinjaman,
    this.eligible = true,
    this.message,
    this.tempoKca,
    this.bungaTotalKca,
    this.adminFee,
    this.totalPelunasanKca,
    this.tenor,
    this.bungaPerBulan,
    this.angsuranPerBulan,
    this.totalBayar,
    this.bungaTotalKrasida,
    this.perbandinganTenor,
  });

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }
}

enum SkemaType { tunai, kca, krasida }

class SimulasiTenor {
  final int tenor;
  final double bungaPerBulan;
  final int angsuranPerBulan;
  final int totalBayar;
  final int bungaTotal;
  final bool isSelected;

  SimulasiTenor({
    required this.tenor,
    required this.bungaPerBulan,
    required this.angsuranPerBulan,
    required this.totalBayar,
    required this.bungaTotal,
    this.isSelected = false,
  });
}
```

### 7.2 Service: Financing Calculator (3 Skema)

```dart
// ============================================
// SERVICE: FinancingCalculator
// ============================================
class FinancingCalculator {
  final FinancingConfig config;
  final List<FinancingTenor> tenors;

  FinancingCalculator({required this.config, required this.tenors});

  // ─── PEMBULATAN ───
  static int roundUp(int value, int factor) {
    return ((value + factor - 1) ~/ factor) * factor;
  }

  static int roundDown(int value, int factor) {
    return (value ~/ factor) * factor;
  }

  // ═══════════════════════════════════════════════════════════════
  // SKEMA 1: TUNAI
  // ═══════════════════════════════════════════════════════════════
  SimulasiResult simulasiTunai({required int hargaLelang}) {
    return SimulasiResult(
      skema: SkemaType.tunai,
      hargaLelang: hargaLelang,
      eligible: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SKEMA 2: KCA (Kredit Cicilan Angsuran)
  // ═══════════════════════════════════════════════════════════════
  SimulasiResult simulasiKca({required int hargaLelang}) {
    // 1. Hitung Uang Muka KCA
    int uangMuka = roundDown(
      (hargaLelang * config.umPercentageKca).round(), 1000
    );

    // 2. Hitung Uang Pinjaman
    int uangPinjaman = hargaLelang - uangMuka;

    // 3. Validasi minimum UP
    if (uangPinjaman < config.minimumUpKca) {
      return SimulasiResult(
        skema: SkemaType.kca,
        hargaLelang: hargaLelang,
        uangMuka: uangMuka,
        uangPinjaman: uangPinjaman,
        eligible: false,
        message: 'Barang ini hanya tersedia untuk pembelian tunai. '
            'Uang pinjaman Rp ${uangPinjaman} di bawah minimum KCA (Rp ${config.minimumUpKca}).',
      );
    }

    // 4. Hitung Bunga KCA (flat per bulan × tempo)
    int bungaTotal = (uangPinjaman * config.bungaKca * config.tempoKca).round();

    // 5. Total pelunasan
    int totalPelunasan = uangPinjaman + bungaTotal + config.adminFeeFlat;

    return SimulasiResult(
      skema: SkemaType.kca,
      hargaLelang: hargaLelang,
      uangMuka: uangMuka,
      uangPinjaman: uangPinjaman,
      eligible: true,
      tempoKca: config.tempoKca,
      bungaTotalKca: bungaTotal,
      adminFee: config.adminFeeFlat,
      totalPelunasanKca: totalPelunasan,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SKEMA 3: KRASIDA (Kredit Gadai Sistem Angsuran)
  // ═══════════════════════════════════════════════════════════════
  SimulasiResult simulasiKrasida({
    required int hargaLelang,
    required int tenor,
  }) {
    // 1. Hitung Uang Muka KRASIDA
    int uangMuka = roundDown(
      (hargaLelang * config.umPercentageKrasida).round(), 1000
    );

    // 2. Hitung Uang Pinjaman
    int uangPinjaman = hargaLelang - uangMuka;

    // 3. Validasi minimum UP
    if (uangPinjaman < config.minimumUpKrasida) {
      return SimulasiResult(
        skema: SkemaType.krasida,
        hargaLelang: hargaLelang,
        uangMuka: uangMuka,
        uangPinjaman: uangPinjaman,
        eligible: false,
        message: 'Barang ini hanya tersedia untuk pembelian tunai. '
            'Uang pinjaman Rp ${uangPinjaman} di bawah minimum KRASIDA (Rp ${config.minimumUpKrasida}).',
      );
    }

    // 4. Ambil konfigurasi tenor
    FinancingTenor? tenorConfig = tenors.firstWhere(
      (t) => t.months == tenor && t.isActive,
      orElse: () => throw Exception('Tenor $tenor tidak tersedia'),
    );

    // 5. Hitung Angsuran
    int angsuran = roundUp(
      ((uangPinjaman * tenorConfig.multiplier) / tenor).round(), 100
    );

    // 6. Hitung Total
    int totalBayar = angsuran * tenor;
    int bungaTotal = totalBayar - uangPinjaman;

    // 7. Hitung perbandingan semua tenor
    List<SimulasiTenor> perbandingan = tenors
        .where((t) => t.isActive)
        .map((t) {
          int ang = roundUp(
            ((uangPinjaman * t.multiplier) / t.months).round(), 100
          );
          int tot = ang * t.months;
          return SimulasiTenor(
            tenor: t.months,
            bungaPerBulan: t.bungaFlat,
            angsuranPerBulan: ang,
            totalBayar: tot,
            bungaTotal: tot - uangPinjaman,
            isSelected: t.months == tenor,
          );
        }).toList();

    return SimulasiResult(
      skema: SkemaType.krasida,
      hargaLelang: hargaLelang,
      uangMuka: uangMuka,
      uangPinjaman: uangPinjaman,
      eligible: true,
      tenor: tenor,
      bungaPerBulan: tenorConfig.bungaFlat,
      angsuranPerBulan: angsuran,
      totalBayar: totalBayar,
      bungaTotalKrasida: bungaTotal,
      perbandinganTenor: perbandingan,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SIMULASI PAKET AKAD (semua skema)
  // ═══════════════════════════════════════════════════════════════
  List<SimulasiResult> simulasiPaketAkad({
    required List<AuctionItem> barangPaket,
    required int tenorKrasida,
  }) {
    int totalHarga = barangPaket.fold(0, (sum, b) => sum + b.hargaLelang);

    return [
      simulasiTunai(hargaLelang: totalHarga),
      simulasiKca(hargaLelang: totalHarga),
      simulasiKrasida(hargaLelang: totalHarga, tenor: tenorKrasida),
    ];
  }
}
```

### 7.3 Database Schema (SQLite)

```sql
-- ============================================
-- TABEL: Barang Lelang
-- ============================================
CREATE TABLE auction_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  credit_number TEXT NOT NULL,
  nama_nasabah TEXT NOT NULL,
  nama_barang TEXT NOT NULL,
  kategori TEXT NOT NULL,
  kadar INTEGER NOT NULL,
  berat_kotor REAL,
  berat_bersih REAL NOT NULL,
  up_asli INTEGER,
  harga_lelang INTEGER NOT NULL,
  harga_dasar INTEGER,
  kondisi TEXT,
  deskripsi TEXT,
  foto_paths TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  tanggal_lelang TEXT NOT NULL,
  tanggal_terjual TEXT,
  harga_terjual INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_credit_number ON auction_items(credit_number);
CREATE INDEX idx_kadar ON auction_items(kadar);
CREATE INDEX idx_kategori ON auction_items(kategori);
CREATE INDEX idx_is_active ON auction_items(is_active);
CREATE INDEX idx_tanggal_lelang ON auction_items(tanggal_lelang);

-- ============================================
-- TABEL: Konfigurasi Pembiayaan (Updated v3.0)
-- ============================================
CREATE TABLE financing_config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  stl_price INTEGER NOT NULL DEFAULT 502894,
  hdle_price INTEGER NOT NULL DEFAULT 550000,
  loan_ratio REAL NOT NULL DEFAULT 0.95,
  admin_fee_flat INTEGER NOT NULL DEFAULT 15000,
  um_percentage_kca REAL NOT NULL DEFAULT 0.192,
  um_percentage_krasida REAL NOT NULL DEFAULT 0.185,
  bunga_kca REAL NOT NULL DEFAULT 0.0125,
  tempo_kca INTEGER NOT NULL DEFAULT 4,
  minimum_up_kca INTEGER NOT NULL DEFAULT 500000,
  minimum_up_krasida INTEGER NOT NULL DEFAULT 500000,
  is_active INTEGER NOT NULL DEFAULT 1,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO financing_config (
  stl_price, hdle_price, loan_ratio, admin_fee_flat,
  um_percentage_kca, um_percentage_krasida,
  bunga_kca, tempo_kca, minimum_up_kca, minimum_up_krasida
) VALUES (
  502894, 550000, 0.95, 15000,
  0.192, 0.185,
  0.0125, 4, 500000, 500000
);

-- ============================================
-- TABEL: Tenor KRASIDA
-- ============================================
CREATE TABLE financing_tenors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  months INTEGER NOT NULL UNIQUE,
  multiplier REAL NOT NULL,
  bunga_flat REAL NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1
);

INSERT INTO financing_tenors (months, multiplier, bunga_flat) VALUES
  (6,  1.075, 0.0125),
  (12, 1.150, 0.0125),
  (18, 1.234, 0.0130),
  (24, 1.312, 0.0130),
  (36, 1.504, 0.0140);
```

---

## 8. Perbandingan: Dokumentasi Lama vs Revisi v3.0

| Aspek | Dokumentasi Lama | Revisi v3.0 |
|-------|-----------------|-------------|
| **Skema** | Hanya KRASIDA | **Tunai + KCA + KRASIDA** |
| **KCA** | Tidak ada | **Lengkap: tempo 4 bln, bunga flat, tanpa angsuran rutin** |
| **Harga Jual** | Auto-calculate dari HDLE | **Manual input admin** (Harga Lelang) |
| **UM KCA** | Tidak ada | **19.2% dari Harga Lelang** |
| **UM KRASIDA** | 18.5% (satu saja) | **18.5% dari Harga Lelang** (dipisah dari KCA) |
| **Bunga KCA** | Tidak ada | **1.25% flat per bulan × 4 bulan** |
| **Context** | Hanya Regular (Gadai) | **Lelang (Auction)** + Regular |
| **Multiplier** | Digunakan | Divalidasi = Bunga Flat equivalen |
| **Pembulatan** | Tidak detail | **Aturan lengkap per field** |
| **Minimum UP** | Tidak ada | **KCA & KRASIDA masing-masing** |
| **Paket Akad** | Konsep saja | **Formula lengkap untuk 3 skema** |
| **Preview Admin** | Tidak ada | **Real-time preview 3 skema** |
| **UI Mockup** | Tidak ada | **ASCII mockup lengkap** |
| **Code** | Referensi file path | **Full Dart code: Model + Service + SQL** |
| **Skema Enum** | Tidak ada | **`SkemaType.tunai / .kca / .krasida`** |

---

## 9. Batasan & Disclaimer

1. **Simulasi bersifat estimasi**, bukan nilai final pembiayaan.
2. Nilai final mengikuti verifikasi dan ketentuan outlet Pegadaian.
3. Aplikasi tetap offline — perubahan kebijakan dari pusat harus diinput manual oleh admin.
4. KCA: Nasabah harus melunasi dalam tempo 4 bulan, jika tidak ada konsekuensi sesuai ketentuan.
5. KRASIDA: Angsuran tetap per bulan, keterlambatan dikenakan denda sesuai ketentuan.
6. Simulasi paling akurat untuk barang dengan data lengkap (kadar, berat, harga lelang).
7. Harga emas (HDLE) dapat berubah — admin perlu update konfigurasi secara berkala.

---

## 10. Rekomendasi Pengembangan Berikutnya

- [ ] **UI Admin Konfigurasi**: Form untuk mengubah semua parameter (STL, HDLE, bunga KCA/KRASIDA, UM %, tempo)
- [ ] **Slider Uang Muka Kustom**: Nasabah bisa geser UM 10%-30% untuk melihat dampak angsuran
- [ ] **Export Simulasi**: Generate PDF atau share ke WhatsApp (per skema)
- [ ] **Indikator Paket**: Badge "📦 Paket" di katalog untuk barang dengan nomor akad sama
- [ ] **Statistik**: Barang paling banyak dilihat/disimulasikan per skema
- [ ] **Reminder KCA**: Notifikasi lokal untuk nasabah KCA mendekati tempo (opsional, jika ada local notification)
- [ ] **Backup/Restore**: Export/import database ke file JSON/Excel
- [ ] **Multi-Cabang**: Jika aplikasi digunakan di beberapa cabang (dengan sync manual)

---

*Dokumentasi ini merupakan revisi v3.0 dari simulasi_pembiayaan.md berdasarkan klarifikasi bisnis (3 skema: Tunai, KCA, KRASIDA) dan analisis dokumen Excel referensi. Segala perubahan harus didokumentasikan di bagian Riwayat Revisi.*

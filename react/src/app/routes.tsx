import { useEffect, useState, type ReactNode } from "react";
import { Link, createBrowserRouter } from "react-router";
import { AlertTriangle, Archive, Calculator, CheckCircle2, ChevronLeft, ChevronRight, Clock3, CloudUpload, Database, Delete, Edit3, FilePlus2, Folder, Gem, HardDrive, Home, LockKeyhole, LogOut, Package, Plus, Search, Settings, ShieldCheck, SlidersHorizontal, Star, Trash2, X } from "lucide-react";
import { toast, Toaster } from "sonner";
import { ImageWithFallback } from "./components/figma/ImageWithFallback";
import pegadaianSyariahLogo from "../imports/6594c69719b94-pagadaian-syariah_1.png";
import { calculateFinancingByItemConfig, mockItemFinancingConfig } from "./financing";

const items = [
  { name: "Cincin Emas 18K 4.5g", category: "Perhiasan", gram: 4.5, price: "Rp 4.250.000", image: "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=520&h=760&fit=crop&auto=format" },
  { name: "HP Samsung Galaxy S23", category: "Elektronik", price: "Rp 7.800.000", image: "https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=520&h=760&fit=crop&auto=format" },
  { name: "Gelang Rantai Emas 22K 10.5g", category: "Perhiasan Emas", gram: 10.5, price: "Rp 11.200.000", image: "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=520&h=760&fit=crop&auto=format" },
  { name: "Laptop Asus Zenbook 14", category: "Elektronik", price: "Rp 9.400.000", image: "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=520&h=760&fit=crop&auto=format" },
  { name: "Antam Logam Mulia 10g", category: "Logam Mulia", price: "Rp 11.850.000", image: "https://images.unsplash.com/photo-1610375461246-83df859d849d?w=520&h=760&fit=crop&auto=format" },
  { name: "Gelang Emas Putih 6.1g", category: "Perhiasan", gram: 6.1, price: "Rp 6.120.000", image: "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=520&h=760&fit=crop&auto=format" },
  { name: "iPhone 14 Pro 128GB", category: "Elektronik", price: "Rp 10.750.000", image: "https://images.unsplash.com/photo-1678652197831-2d180705cd2c?w=520&h=760&fit=crop&auto=format" },
  { name: "Motor Honda Vario 2021", category: "Kendaraan", price: "Rp 14.500.000", image: "https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=520&h=760&fit=crop&auto=format" },
];

const defaultGoldPricePerGram = 1120000;

function formatRupiah(value: number) {
  return `Rp ${Math.round(value).toLocaleString("id-ID")}`;
}

function useGoldPricePerGram() {
  const [goldPrice, setGoldPrice] = useState(defaultGoldPricePerGram);

  useEffect(() => {
    const saved = window.localStorage.getItem("pegadaian_gold_price_per_gram");
    if (saved) setGoldPrice(Number(saved));
  }, []);

  return [goldPrice, setGoldPrice] as const;
}

function getDisplayPrice(item: { price: string; gram?: number }, goldPrice: number) {
  return item.gram ? formatRupiah(item.gram * goldPrice) : item.price;
}

function getCategoryBadgeClass(category: string) {
  if (category.includes("Emas") || category === "Perhiasan") return "bg-secondary text-[#1B5E20]";
  if (category === "Elektronik") return "bg-[#E3F2FD] text-[#0D47A1]";
  if (category === "Logam Mulia") return "bg-[#FFF8E1] text-[#8A5A00]";
  if (category === "Kendaraan") return "bg-[#F3E5F5] text-[#6A1B9A]";
  return "bg-[#F5F5F5] text-[#616161]";
}

function Logo() {
  return (
    <div className="flex h-16 w-[210px] items-center rounded-2xl bg-white">
      <ImageWithFallback src={pegadaianSyariahLogo} alt="Logo Pegadaian Syariah" className="h-12 w-full object-contain object-left" />
    </div>
  );
}

function Header() {
  return (
    <header className="px-10 pb-5 pt-6">
      <div className="flex min-h-[108px] items-center justify-between gap-8 rounded-[28px] border border-white/20 bg-white/10 px-7 shadow-lg backdrop-blur-md">
        <div className="flex min-w-0 items-center gap-7">
          <Logo />
          <div className="h-16 w-px shrink-0 bg-border" />
          <div className="min-w-0">
            <h1 className="mt-1 max-w-5xl text-[32px] font-bold leading-tight text-white">Cabang Simpang Patal</h1>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-3">
          <Link to="/admin" aria-label="Masuk panel admin" className="flex min-h-12 items-center gap-2 rounded-full border border-white/30 bg-white/20 px-5 text-[16px] font-semibold text-white transition hover:bg-white/30 backdrop-blur-sm">
            <LockKeyhole className="size-5" />
            Admin
          </Link>
          <div className="flex min-h-12 items-center gap-3 rounded-full border border-white/20 bg-white/10 px-5 text-white/90 backdrop-blur-sm">
            <Clock3 className="size-5" />
            <span className="text-lg font-semibold">10:45 AM</span>
          </div>
        </div>
      </div>
    </header>
  );
}

function CatalogPage() {
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [goldPrice] = useGoldPricePerGram();

  return (
    <main className="min-h-screen w-full max-w-full overflow-x-hidden text-foreground">
      <div className="relative mx-auto flex min-h-screen max-w-[1366px] flex-col overflow-hidden">
        <Header />

        <section className="px-10 pb-9 pt-1">
          <div className="rounded-[40px] border border-border bg-white p-8 shadow-[0_15px_50px_rgba(0,0,0,0.06)]">
            <div className="grid items-center gap-10 lg:grid-cols-[1fr_390px]">
              <div>
                <h2 className="max-w-5xl text-[34px] font-bold leading-tight text-[#212121]">
                  Temukan barang lelang terpercaya dengan tampilan yang jelas dan mudah dibaca.
                </h2>
                <p className="mt-4 max-w-3xl text-[20px] font-medium leading-9 text-[#616161]">
                  Gunakan pencarian besar atau filter sederhana untuk melihat perhiasan emas, elektronik, logam mulia, dan kendaraan.
                </p>
              </div>
              <div className="rounded-[32px] border border-[#E8F5E9] bg-[#F1F8F1] p-6 shadow-sm">
                <p className="text-[15px] font-bold text-[#1B5E20]">Harga emas hari ini</p>
                <p className="mt-1 text-[36px] font-bold text-[#00AA13]">{formatRupiah(goldPrice)} / gram</p>
                <p className="mt-1 text-[14px] font-medium text-[#1B5E20]/70">Harga produk emas otomatis menyesuaikan.</p>
              </div>
            </div>

            <div className="mt-8 flex gap-5">
              <div className="flex h-[80px] flex-1 items-center gap-5 rounded-full border border-[#E0E0E0] bg-[#F9FAFB] px-8 transition-all focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/10">
                <Search className="size-8 text-primary" />
                <span className="text-[24px] font-medium text-[#9E9E9E]">Cari perhiasan, handphone, laptop...</span>
              </div>
              <button onClick={() => setIsFilterOpen(true)} className="flex h-[80px] items-center gap-4 rounded-full bg-[#00AA13] px-10 text-[20px] font-bold text-white shadow-lg transition hover:bg-[#009110] active:scale-[0.98]">
                <SlidersHorizontal className="size-6" />
                Filter
              </button>
            </div>
          </div>
        </section>

        <section className="flex-1 px-10 py-8">
          <div className="mb-6 flex items-end justify-between">
            <div>
              <h2 className="text-[32px] font-bold text-white text-[#000000]">Barang Lelang Tersedia</h2>
              <p className="mt-2 text-[18px] font-medium text-white/80 text-[#000000cc]">Kartu dibuat lebih besar agar nyaman dibaca nasabah lanjut usia.</p>
            </div>
            <div className="rounded-full bg-white px-6 py-3 text-[16px] font-bold text-[#00AA13] shadow-md">42 barang aktif</div>
          </div>

          <div className="grid grid-flow-dense grid-cols-2 gap-7 lg:grid-cols-4">
            {items.map((item, index) => {
              const category = index === 2 ? "Perhiasan Emas" : item.category;
              return (
                <Link to="/barang/gelang-rantai-emas" key={item.name} className="group overflow-hidden rounded-[26px] border border-[#D2D2D2] bg-white p-5 shadow-[0_10px_26px_rgba(33,33,33,0.055)] transition duration-300 hover:-translate-y-1 hover:border-primary/70">
                  <div className="relative flex aspect-[0.78] items-center justify-center overflow-hidden rounded-[24px] bg-[#F7F8F7]">
                    <img src={item.image} alt={item.name} className="h-full w-full object-contain p-3 transition-transform duration-700 ease-out group-hover:scale-105" />
                  </div>
                  <div className={`mt-5 inline-flex rounded-full px-4 py-2 text-[15px] font-semibold ${getCategoryBadgeClass(category)}`}>{category}</div>
                  <h3 className="mt-4 min-h-[64px] text-[21px] font-bold leading-snug text-[#212121]">{item.name}</h3>
                  <div className="mt-4 rounded-[20px] bg-[#F9FAFB] p-4">
                    <p className="text-[14px] font-semibold uppercase tracking-[0.08em] text-[#616161]">Harga awal</p>
                    <p className="mt-1 text-[31px] font-bold leading-tight text-primary">{getDisplayPrice(item, goldPrice)}</p>
                  </div>
                </Link>
              );
            })}
          </div>
        </section>

        {isFilterOpen && <FilterSheet onClose={() => setIsFilterOpen(false)} />}

        <footer className="flex h-[88px] items-center justify-between border-t border-white/10 bg-white/5 px-10 text-white/80 backdrop-blur-md">
          <p className="text-[17px] font-medium">Menampilkan <span className="font-bold text-white">12</span> dari <span className="font-bold text-white">48</span> barang</p>
          <div className="flex items-center gap-3">
            <button className="flex size-12 items-center justify-center rounded-full border border-white/20 bg-white/10 text-white transition hover:bg-white/20"><ChevronLeft className="size-5" /></button>
            <span className="rounded-full bg-[#00AA13] px-6 py-3 text-sm font-bold text-white shadow-sm">Halaman 1 dari 4</span>
            <button className="flex size-12 items-center justify-center rounded-full bg-white text-[#00AA13] shadow-md transition hover:bg-white/90"><ChevronRight className="size-5" /></button>
          </div>
        </footer>
      </div>
    </main>
  );
}

function EmptySearchIllustration() {
  return (
    <div className="relative mx-auto h-[250px] w-[330px]">
      <div className="absolute bottom-8 left-10 h-28 w-52 rounded-[28px] border border-[#D6D6D6] bg-white shadow-[0_16px_40px_rgba(33,33,33,0.06)]" />
      <div className="absolute bottom-[116px] left-14 h-12 w-28 rounded-t-[18px] border border-[#D6D6D6] bg-[#E8F5E9]" />
      <div className="absolute bottom-16 left-24 h-20 w-36 rounded-[24px] bg-[#F9FAFB]" />
      <div className="absolute right-10 top-10 flex size-32 items-center justify-center rounded-full border-[14px] border-primary bg-white shadow-[0_14px_35px_rgba(0,170,19,0.12)]">
        <div className="size-12 rounded-full bg-secondary" />
      </div>
      <div className="absolute right-8 top-[128px] h-16 w-5 rotate-[-42deg] rounded-full bg-primary" />
      <div className="absolute left-2 top-8 h-5 w-20 rounded-full bg-[#E0E0E0]" />
      <div className="absolute left-20 top-2 h-4 w-12 rounded-full bg-secondary" />
      <div className="absolute bottom-2 right-24 h-4 w-28 rounded-full bg-[#E0E0E0]" />
    </div>
  );
}

function EmptySearchPage() {
  return (
    <main className="min-h-screen w-full max-w-full overflow-x-hidden text-foreground">
      <div className="mx-auto flex min-h-screen max-w-[1366px] flex-col overflow-hidden">
        <Header />

        <section className="px-10 pb-8 pt-1">
          <div className="flex gap-4 rounded-[32px] border border-border bg-white p-5 shadow-lg">
            <div className="flex h-[72px] flex-1 items-center gap-4 rounded-full border border-[#D0D0D0] bg-white px-7 shadow-[0_5px_18px_rgba(33,33,33,0.04)]">
              <Search className="size-8 text-primary" />
              <span className="text-[22px] font-semibold text-[#212121]">Laptop Rog ROG Zephyrus</span>
              <div className="ml-auto flex size-10 items-center justify-center rounded-full bg-[#F1F1F1] text-[#616161]"><X className="size-5" /></div>
            </div>
            <button className="flex h-[72px] items-center gap-3 rounded-full border-2 border-primary bg-white px-9 text-[19px] font-bold text-primary transition hover:bg-secondary">
              <SlidersHorizontal className="size-6" />
              Filter
            </button>
          </div>
        </section>

        <section className="flex flex-1 items-center justify-center px-10 py-10">
          <div className="w-full max-w-[760px] rounded-[36px] border border-border bg-white px-10 py-12 text-center shadow-[0_16px_44px_rgba(33,33,33,0.045)]">
            <EmptySearchIllustration />
            <h1 className="mx-auto mt-8 max-w-5xl text-[36px] font-bold leading-tight text-[#212121]">Barang Tidak Ditemukan</h1>
            <p className="mx-auto mt-4 max-w-[650px] text-[19px] font-medium leading-8 text-[#616161]">Maaf, barang lelang dengan kata kunci tersebut tidak tersedia di database outlet saat ini. Coba kata kunci lain atau reset filter.</p>
            <Link to="/" className="mt-8 inline-flex min-h-14 items-center justify-center rounded-full bg-primary px-9 text-[18px] font-bold text-white transition hover:bg-[#059212] active:scale-[0.98]">
              Reset Pencarian &amp; Filter
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}

function Chip({ children, selected = false }: { children: string; selected?: boolean }) {
  return (
    <button className={`min-h-11 rounded-full border px-5 text-[14px] font-bold transition ${selected ? "border-primary bg-primary text-white" : "border-border bg-white text-[#616161] hover:border-primary hover:text-primary"}`}>
      {children}
    </button>
  );
}

function FilterSheet({ onClose }: { onClose: () => void }) {
  return (
    <div className="absolute inset-0 z-20 flex items-center justify-center bg-[#F9FAFB]/88 px-10">
      <div className="w-full max-w-[1050px] overflow-hidden rounded-[32px] border border-border bg-white shadow-[0_22px_60px_rgba(33,33,33,0.12)]">
        <div className="grid items-center gap-6 border-b border-border bg-white px-8 py-7 lg:grid-cols-[1fr_auto]">
          <div>
            <h2 className="max-w-5xl text-[32px] font-bold leading-tight text-[#212121]">Filter Barang Lelang</h2>
            <p className="mt-2 text-[17px] font-medium leading-7 text-[#616161]">Pilih kriteria utama agar daftar barang lebih mudah dibaca dan cepat ditemukan.</p>
          </div>
          <button onClick={onClose} className="flex size-12 items-center justify-center rounded-full border border-border bg-[#F9FAFB] text-[#616161] transition hover:border-primary hover:text-primary">
            <X className="size-6" />
          </button>
        </div>

        <div className="grid grid-flow-dense gap-6 bg-[#F9FAFB] p-8 lg:grid-cols-[1fr_1fr]">
          <section className="rounded-[26px] border border-border bg-white p-6 shadow-[0_10px_26px_rgba(33,33,33,0.035)]">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h3 className="text-[21px] font-bold text-[#212121]">Kategori Barang</h3>
                <p className="mt-1 text-[15px] font-medium text-[#616161]">Pilih satu atau beberapa kategori.</p>
              </div>
              <span className="rounded-full bg-secondary px-4 py-2 text-[13px] font-semibold text-[#1B5E20]">2 dipilih</span>
            </div>
            <div className="mt-5 grid grid-cols-2 gap-3">
              <Chip>Semua</Chip>
              <Chip selected>Perhiasan Emas</Chip>
              <Chip selected>Elektronik</Chip>
              <Chip>Logam Mulia</Chip>
            </div>
          </section>

          <section className="rounded-[26px] border border-border bg-white p-6 shadow-[0_10px_26px_rgba(33,33,33,0.035)]">
            <h3 className="text-[21px] font-bold text-[#212121]">Harga Dasar Lelang</h3>
            <p className="mt-1 text-[15px] font-medium text-[#616161]">Gunakan batas minimum dan maksimum.</p>
            <div className="mt-5 grid grid-cols-[1fr_auto_1fr] items-end gap-4">
              <label className="block">
                <span className="text-[14px] font-semibold text-[#616161]">Minimum</span>
                <div className="mt-2 rounded-[22px] border border-border bg-[#F9FAFB] px-5 py-4 text-[21px] font-bold text-[#212121]">Rp 500.000</div>
              </label>
              <div className="mb-5 h-px w-8 bg-border" />
              <label className="block">
                <span className="text-[14px] font-semibold text-[#616161]">Maksimum</span>
                <div className="mt-2 rounded-[22px] border border-border bg-[#F9FAFB] px-5 py-4 text-[21px] font-bold text-[#212121]">Rp 15.000.000</div>
              </label>
            </div>
          </section>

          <section className="rounded-[26px] border border-border bg-white p-6 shadow-[0_10px_26px_rgba(33,33,33,0.035)]">
            <h3 className="text-[21px] font-bold text-[#212121]">Kondisi Barang</h3>
            <p className="mt-1 text-[15px] font-medium text-[#616161]">Tampilkan barang dengan kondisi tertentu.</p>
            <div className="mt-5 grid grid-cols-3 gap-3">
              <Chip selected>Sangat Baik</Chip>
              <Chip selected>Baik</Chip>
              <Chip>Cukup Baik</Chip>
            </div>
          </section>

          <aside className="rounded-[26px] border border-[#D7E7D8] bg-secondary p-6 shadow-[0_10px_26px_rgba(33,33,33,0.025)]">
            <h3 className="text-[21px] font-bold text-[#1B5E20]">Ringkasan Filter</h3>
            <div className="mt-5 grid gap-3">
              <div className="flex items-center justify-between rounded-2xl bg-white px-4 py-3">
                <span className="text-[15px] font-medium text-[#616161]">Kategori</span>
                <span className="text-[15px] font-bold text-[#212121]">Emas, Elektronik</span>
              </div>
              <div className="flex items-center justify-between rounded-2xl bg-white px-4 py-3">
                <span className="text-[15px] font-medium text-[#616161]">Harga</span>
                <span className="text-[15px] font-bold text-[#212121]">Rp 500 rb - 15 jt</span>
              </div>
              <div className="flex items-center justify-between rounded-2xl bg-white px-4 py-3">
                <span className="text-[15px] font-medium text-[#616161]">Kondisi</span>
                <span className="text-[15px] font-bold text-[#212121]">Sangat Baik, Baik</span>
              </div>
            </div>
            <p className="mt-5 text-[14px] font-medium leading-7 text-[#1B5E20]">Filter dibuat sederhana agar nyaman digunakan pada tablet kiosk dan mudah dipahami nasabah.</p>
          </aside>
        </div>

        <div className="flex items-center gap-4 border-t border-border bg-white px-8 py-6">
          <button className="min-h-14 w-[34%] rounded-full border border-primary bg-white px-8 text-[17px] font-semibold text-primary transition hover:bg-secondary">Reset Filter</button>
          <button onClick={onClose} className="min-h-14 flex-1 rounded-full bg-primary px-8 text-[18px] font-bold text-white transition hover:bg-[#059212]">Terapkan Filter</button>
        </div>
      </div>
    </div>
  );
}

function SpecRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="grid grid-cols-[140px_1fr] gap-4 py-3 text-[16px]">
      <dt className="font-semibold text-[#616161]">{label}</dt>
      <dd className="font-semibold text-[#212121]">{value}</dd>
    </div>
  );
}

function DetailPage() {
  const [goldPrice] = useGoldPricePerGram();
  const [isFinancingOpen, setIsFinancingOpen] = useState(false);
  const itemPrice = 10.5 * goldPrice;
  const calculatedPrice = formatRupiah(itemPrice);

  return (
    <main className="min-h-screen w-full max-w-full overflow-x-hidden text-foreground">
      <div className="mx-auto min-h-screen max-w-[1366px] px-10 py-8">
        <nav className="flex items-center justify-between rounded-[28px] border border-white/20 bg-white/10 px-6 py-4 shadow-lg backdrop-blur-md">
          <Link to="/" className="inline-flex min-h-12 items-center rounded-full border border-white/30 bg-white/20 px-6 text-[17px] font-semibold text-white transition hover:bg-white/30 backdrop-blur-sm">
            ← Kembali ke Katalog
          </Link>
          <div className="flex items-center gap-3">
            <div className="rounded-full bg-[#00AA13] px-5 py-3 text-[15px] font-semibold text-white shadow-sm">Perhiasan Emas</div>
            <div className="rounded-full border border-white/20 bg-white/10 px-5 py-3 text-[15px] font-medium text-white/90 backdrop-blur-sm">CPS Simpang Patal</div>
          </div>
        </nav>

        <section className="mt-7 rounded-[32px] border border-border bg-white p-7 shadow-[0_12px_34px_rgba(33,33,33,0.05)]">
          <div className="grid gap-8 lg:grid-cols-[1.08fr_0.92fr]">
            <div>
              <div className="overflow-hidden rounded-[28px] border border-[#D6D6D6] bg-[#FBFBFB] p-5">
                <div className="relative flex h-[620px] items-center justify-center overflow-hidden rounded-[24px] bg-[#F7F8F7]">
                  <img src="https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=760&h=1100&fit=crop&auto=format" alt="Gelang rantai emas 22 karat" className="h-full w-full object-contain p-6 transition-transform duration-700 ease-out hover:scale-105" />
                  <div className="absolute bottom-5 left-5 rounded-2xl bg-white/95 px-4 py-3 shadow-[0_8px_24px_rgba(33,33,33,0.08)]">
                    <p className="text-[13px] font-semibold text-[#1B5E20]">Mode portrait-safe</p>
                    <p className="mt-0.5 text-[12px] font-medium text-[#616161]">Gambar kamera lokal ditampilkan penuh, tidak dipotong.</p>
                  </div>
                </div>
              </div>

              <div className="mt-5 grid grid-cols-[1fr_auto_1fr] items-center gap-5">
                <button className="min-h-14 rounded-full border-2 border-primary bg-white px-6 text-[17px] font-semibold text-primary transition hover:bg-secondary">&lt; Sebelumnya</button>
                <div className="flex items-center justify-center gap-2">
                  {[0, 1, 2, 3].map((dot) => (
                    <span key={dot} className={`h-3 rounded-full ${dot === 1 ? "w-10 bg-primary" : "w-3 bg-[#D9D9D9]"}`} />
                  ))}
                </div>
                <button className="min-h-14 rounded-full border-2 border-primary bg-white px-6 text-[17px] font-semibold text-primary transition hover:bg-secondary">Selanjutnya &gt;</button>
              </div>
            </div>

            <aside className="flex flex-col">
              <div className="rounded-[28px] border border-border bg-[#F9FAFB] p-6">
                <h1 className="max-w-5xl text-[38px] font-bold leading-tight text-[#212121]">Gelang Rantai Emas 22K 10.5g</h1>
                <p className="mt-4 text-[18px] font-medium leading-8 text-[#616161]">Gelang emas model rantai dengan pengunci kokoh, warna kuning berkilau alami, kondisi terawat tanpa cacat fisik.</p>
              </div>

              <div className="mt-5 grid grid-flow-dense grid-cols-2 gap-4">
                {[
                  ["Kategori", "Perhiasan Emas"],
                  ["Berat", "10.50 gram"],
                  ["Karat", "22 Karat"],
                  ["Kondisi", "Sangat Baik (95%)"],
                ].map(([label, value]) => (
                  <div key={label} className="rounded-[22px] border border-border bg-white p-5 shadow-[0_8px_22px_rgba(33,33,33,0.035)]">
                    <p className="text-[14px] font-semibold text-[#616161]">{label}</p>
                    <p className="mt-2 text-[20px] font-bold leading-snug text-[#212121]">{value}</p>
                  </div>
                ))}
              </div>

              <div className="mt-5 rounded-[28px] border border-[#F3D27A] bg-[#FFFDF5] p-6 shadow-[0_10px_28px_rgba(249,168,37,0.08)]">
                <div className="flex items-start justify-between gap-5">
                  <div>
                    <p className="text-[15px] font-semibold uppercase tracking-[0.08em] text-[#8A5A00]">Harga Dasar Lelang</p>
                    <p className="mt-2 text-[42px] font-bold leading-tight text-accent">{calculatedPrice}</p>
                  </div>
                  <div className="rounded-2xl bg-white px-4 py-3 text-right">
                    <p className="text-[13px] font-medium text-[#616161]">Acuan emas</p>
                    <p className="text-[17px] font-bold text-primary">{formatRupiah(goldPrice)}/g</p>
                  </div>
                </div>
                <div className="mt-5 flex gap-3">
                  <button onClick={() => setIsFinancingOpen(true)} className="inline-flex min-h-14 w-full items-center justify-center gap-3 rounded-full bg-primary px-6 text-[18px] font-bold text-white transition hover:bg-[#059212] active:scale-[0.98]">
                    <Calculator className="size-6" /> Lihat Simulasi Pembiayaan
                  </button>
                </div>
                <p className="mt-4 text-[15px] font-medium leading-7 text-[#616161]">Harga ini mengikuti update harga emas harian dari panel admin.</p>
              </div>

              <div className="mt-5 rounded-[24px] border border-[#D7E7D8] bg-secondary p-5">
                <p className="text-[16px] font-semibold leading-7 text-[#1B5E20]">Untuk informasi lelang, silakan hubungi petugas cabang. Kiosk ini hanya menampilkan katalog dan tidak menyediakan transaksi langsung.</p>
              </div>
            </aside>
          </div>
        </section>
        {isFinancingOpen && <FinancingSimulationModal itemPrice={itemPrice} onClose={() => setIsFinancingOpen(false)} />}
      </div>
    </main>
  );
}


function FinancingSimulationModal({ itemPrice, onClose }: { itemPrice: number; onClose: () => void }) {
  const config = { ...mockItemFinancingConfig, hargaBarang: itemPrice };
  const [selectedTenor, setSelectedTenor] = useState(config.tenorMonths[1] ?? config.tenorMonths[0]);
  const [selectedDpPercent, setSelectedDpPercent] = useState(config.dpPercentOptions[1] ?? config.dpPercentOptions[0]);
  const result = calculateFinancingByItemConfig(itemPrice, selectedDpPercent, selectedTenor, config);

  const primaryRows: Array<[string, string]> = [
    ["Harga Barang", formatRupiah(result.hargaBarang)],
    ["Nominal DP", formatRupiah(result.dpNominal)],
    ["Pokok Pembiayaan", formatRupiah(result.pokokPembiayaan)],
    ["Mu'nah per 10 Hari", formatRupiah(result.munahPer10Days)],
    ["Total Mu'nah", formatRupiah(result.totalMunah)],
    ["Biaya Administrasi", formatRupiah(result.biayaAdministrasi)],
    ["Biaya Lain", formatRupiah(result.biayaLain)],
  ];

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-[#F9FAFB]/88 px-8">
      <section className="w-full max-w-[1040px] overflow-hidden rounded-[32px] border border-border bg-white shadow-[0_22px_60px_rgba(33,33,33,0.12)]">
        <div className="flex items-start justify-between border-b border-border px-8 py-6">
          <div>
            <h2 className="max-w-5xl text-[30px] font-bold leading-tight text-[#212121]">Simulasi Pembiayaan Syariah</h2>
            <p className="mt-2 text-[16px] font-medium text-[#616161]">Pilih DP dan tenor. Estimasi akan diperbarui otomatis.</p>
          </div>
          <button onClick={onClose} className="flex size-12 items-center justify-center rounded-full border border-border bg-[#F9FAFB] text-[#616161] transition hover:border-primary hover:text-primary"><X className="size-6" /></button>
        </div>

        <div className="bg-[#F9FAFB] p-8">
          <div className="grid gap-5 lg:grid-cols-[1fr_1fr]">
            <section className="rounded-[28px] border border-[#F3D27A] bg-[#FFFDF5] p-6">
              <p className="text-[14px] font-semibold uppercase tracking-[0.08em] text-[#8A5A00]">Estimasi Angsuran per Bulan</p>
              <p className="mt-3 text-[42px] font-bold leading-tight text-accent">{formatRupiah(result.estimasiAngsuranPerBulan)}</p>
              <div className="mt-5 grid grid-cols-2 gap-3">
                <div className="rounded-2xl bg-white p-4">
                  <p className="text-[13px] font-medium text-[#616161]">Total Kewajiban</p>
                  <p className="mt-1 text-[22px] font-bold text-[#212121]">{formatRupiah(result.totalKewajiban)}</p>
                </div>
                <div className="rounded-2xl bg-white p-4">
                  <p className="text-[13px] font-medium text-[#616161]">Tenor Aktif</p>
                  <p className="mt-1 text-[22px] font-bold text-[#212121]">{selectedTenor} bulan</p>
                </div>
              </div>
            </section>

            <section className="rounded-[28px] border border-border bg-white p-6">
              <div>
                <p className="text-[15px] font-semibold text-[#212121]">Pilih DP</p>
                <div className="mt-3 grid grid-cols-4 gap-2">
                  {config.dpPercentOptions.map((percent) => (
                    <button key={percent} onClick={() => setSelectedDpPercent(percent)} className={`min-h-12 rounded-full text-[16px] font-bold transition ${selectedDpPercent === percent ? "bg-primary text-white" : "border border-border bg-white text-[#616161] hover:border-primary hover:text-primary"}`}>{percent}%</button>
                  ))}
                </div>
              </div>

              <div className="mt-5">
                <p className="text-[15px] font-semibold text-[#212121]">Pilih Tenor</p>
                <div className="mt-3 grid grid-cols-5 gap-2">
                  {config.tenorMonths.map((month) => (
                    <button key={month} onClick={() => setSelectedTenor(month)} className={`min-h-12 rounded-full text-[14px] font-bold transition ${selectedTenor === month ? "bg-primary text-white" : "border border-border bg-white text-[#616161] hover:border-primary hover:text-primary"}`}>{month}</button>
                  ))}
                </div>
              </div>

              <div className="mt-5 rounded-2xl border border-[#D7E7D8] bg-secondary p-4 text-[14px] font-medium leading-6 text-[#1B5E20]">
                Mu'nah item: {config.munahInputType === "percent" ? `${config.munahValuePer10Days}% dari pokok pembiayaan` : formatRupiah(config.munahValuePer10Days)} per 10 hari.
              </div>
            </section>
          </div>

          <section className="mt-5 rounded-[28px] border border-border bg-white p-6">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-[20px] font-bold text-[#212121]">Rincian Simulasi</h3>
              <span className="rounded-full bg-secondary px-4 py-2 text-[13px] font-semibold text-[#1B5E20]">{result.totalHariMunah} hari • {result.jumlahPeriodeMunah} periode</span>
            </div>
            <div className="grid gap-x-8 gap-y-3 lg:grid-cols-2">
              {primaryRows.map(([label, value]) => (
                <div key={label} className="flex items-center justify-between border-b border-border py-3">
                  <p className="text-[15px] font-medium text-[#616161]">{label}</p>
                  <p className="text-[16px] font-bold text-[#212121]">{value}</p>
                </div>
              ))}
              <div className="flex items-center justify-between border-b border-border py-3">
                <p className="text-[15px] font-medium text-[#616161]">DP yang Dipilih</p>
                <p className="text-[16px] font-bold text-[#212121]">{result.dpPercent}%</p>
              </div>
            </div>
          </section>
        </div>

        <div className="border-t border-border bg-white px-8 py-5">
          <p className="text-[14px] font-medium leading-7 text-[#616161]">Simulasi ini bersifat estimasi. Nilai final mengikuti verifikasi petugas dan ketentuan Pegadaian Syariah yang berlaku di outlet.</p>
        </div>
      </section>
    </div>
  );
}

function AdminPinPage() {
  const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "0", "delete"];

  return (
    <main className="relative flex min-h-screen items-center justify-center bg-background px-10 py-8 text-foreground">
      <Link to="/" className="absolute bottom-8 left-10 inline-flex min-h-12 items-center rounded-full border border-primary bg-white px-6 text-[16px] font-semibold text-primary transition hover:bg-secondary">
        ← Batal &amp; Kembali ke Katalog
      </Link>

      <section className="w-full max-w-[500px] rounded-[20px] border border-border bg-white px-10 py-9 text-center shadow-[0_12px_38px_rgba(33,33,33,0.045)]">
        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-[20px] bg-secondary">
          <div className="relative h-10 w-10 rounded-full border-[7px] border-primary">
            <div className="absolute -right-2 top-1/2 h-4 w-6 -translate-y-1/2 rounded-full bg-primary" />
          </div>
        </div>
        <h1 className="mt-5 text-[28px] font-bold leading-tight text-[#212121]">Masuk Panel Admin Cabang</h1>

        <div className="mx-auto mt-7 flex size-16 items-center justify-center rounded-full bg-secondary text-primary">
          <LockKeyhole className="size-8" />
        </div>
        <p className="mt-5 text-[16px] font-semibold text-[#616161]">Masukkan 6-Digit PIN Keamanan Admin</p>

        <div className="mt-7 flex justify-center gap-4">
          {[0, 1, 2, 3, 4, 5].map((slot) => (
            <div key={slot} className="flex size-6 items-center justify-center rounded-full border-2 border-[#1B5E20] bg-white">
              {slot < 3 && <span className="size-3 rounded-full bg-[#1B5E20]" />}
            </div>
          ))}
        </div>

        <div className="mx-auto mt-8 grid max-w-[330px] grid-cols-3 gap-4">
          {keys.map((key) => (
            <button key={key} className="flex size-[94px] items-center justify-center rounded-full border border-border bg-white text-[28px] font-bold text-[#212121] transition hover:border-primary hover:bg-secondary active:scale-95">
              {key === "clear" ? <span className="text-[15px] font-semibold uppercase tracking-[0.08em] text-[#616161]">Clear</span> : key === "delete" ? <Delete className="size-8 text-[#616161]" /> : key}
            </button>
          ))}
        </div>
        <Link to="/admin/dashboard" className="mt-7 inline-flex min-h-12 items-center justify-center rounded-full bg-primary px-8 text-[16px] font-semibold text-white">
          Masuk Dashboard
        </Link>
      </section>
    </main>
  );
}

const recentItems = [
  { name: "Gelang Rantai Emas 22K 10.5g", price: "Rp 11.200.000", image: "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=160&h=160&fit=crop&auto=format" },
  { name: "Cincin Emas 18K 4.5g", price: "Rp 4.250.000", image: "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=160&h=160&fit=crop&auto=format" },
  { name: "HP Samsung Galaxy S23", price: "Rp 7.800.000", image: "https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=160&h=160&fit=crop&auto=format" },
];

function DrawerItem({ icon: Icon, label, active = false, to }: { icon: typeof Home; label: string; active?: boolean; to?: string }) {
  const className = `flex min-h-12 items-center gap-3 rounded-2xl px-4 text-[15px] font-medium transition ${active ? "bg-primary text-white shadow-[0_8px_18px_rgba(0,170,19,0.18)]" : "text-[#616161] hover:bg-secondary hover:text-[#1B5E20]"}`;
  const content = (
    <>
      <Icon className="size-5" />
      <span>{label}</span>
    </>
  );

  return to ? <Link to={to} className={className}>{content}</Link> : <div className={className}>{content}</div>;
}

function StatCard({ icon: Icon, label, value, gold = false }: { icon: typeof Package; label: string; value: string; gold?: boolean }) {
  return (
    <article className="rounded-[24px] border border-border bg-white p-6 shadow-[0_10px_28px_rgba(33,33,33,0.035)]">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-[14px] font-bold text-[#616161]">{label}</p>
          <h3 className="mt-3 text-[26px] font-bold leading-tight text-[#212121]">{value}</h3>
        </div>
        <div className={`flex size-12 items-center justify-center rounded-2xl ${gold ? "bg-[#FFF8E1] text-accent" : "bg-secondary text-primary"}`}>
          <Icon className="size-6" />
        </div>
      </div>
    </article>
  );
}

function AdminDashboardPage() {
  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="dashboard" />

      <section className="overflow-hidden bg-[#F9FAFB] px-8 py-8">
        <header className="flex items-start justify-between">
          <div>
            <h2 className="max-w-5xl text-[32px] font-bold leading-tight text-[#212121]">Ringkasan Katalog Outlet</h2>
            <p className="mt-2 flex items-center gap-2 text-[16px] font-semibold text-[#616161]"><Database className="size-5 text-primary" /> Sistem Database Offline (SQLite) Aktif</p>
          </div>
          <div className="rounded-full border border-border bg-white px-5 py-3 text-[15px] font-medium text-[#616161]">Hari Ini, 10:45 AM</div>
        </header>

        <div className="mt-7 flex items-center justify-between rounded-[24px] border border-[#D7E7D8] bg-white px-6 py-4 shadow-[0_10px_28px_rgba(33,33,33,0.025)]">
          <div className="flex items-center gap-3 text-[16px] font-medium text-[#616161]"><Database className="size-5 text-primary" /> Alur kerja: update harga emas, kelola barang, lalu backup database lokal.</div>
          <Link to="/admin/harga-emas" className="rounded-full bg-primary px-5 py-3 text-[15px] font-semibold text-white">Update Harga Emas</Link>
        </div>

        <div className="mt-7 grid grid-cols-3 gap-5">
          <StatCard icon={Package} label="Total Barang Aktif" value="42 Barang" />
          <StatCard icon={Star} label="Kategori Terbanyak" value="Perhiasan Emas (28)" gold />
          <StatCard icon={Clock3} label="Update Terakhir" value="Hari Ini, 09:30" />
        </div>

        <section className="mt-7 rounded-[24px] border border-border bg-white p-6 shadow-[0_10px_28px_rgba(33,33,33,0.035)]">
          <div className="flex items-center justify-between border-b border-border pb-4">
            <h3 className="text-[20px] font-bold text-[#212121]">Aktivitas Terbaru</h3>
            <span className="rounded-full bg-secondary px-4 py-2 text-[13px] font-bold text-[#1B5E20]">3 item terakhir</span>
          </div>
          <div className="divide-y divide-border">
            {recentItems.map((item) => (
              <div key={item.name} className="grid grid-cols-[64px_1fr_auto] items-center gap-4 py-4">
                <img src={item.image} alt={item.name} className="size-16 rounded-[24px] border border-border bg-white object-contain p-1" />
                <div>
                  <p className="text-[17px] font-semibold text-[#212121]">{item.name}</p>
                  <p className="mt-1 text-[13px] font-semibold text-[#616161]">Ditambahkan ke database SQLite lokal</p>
                </div>
                <p className="text-[20px] font-semibold text-primary">{item.price}</p>
              </div>
            ))}
          </div>
        </section>
      </section>
    </main>
  );
}

const adminRows = [
  { no: 1, name: "Cincin Emas Solitaire 18K", category: "Perhiasan Emas", price: "Rp 6.400.000", status: "Aktif", image: "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=120&h=120&fit=crop&auto=format" },
  { no: 2, name: "Laptop Lenovo ThinkPad", category: "Elektronik", price: "Rp 5.200.000", status: "Aktif", image: "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=120&h=120&fit=crop&auto=format" },
  { no: 3, name: "Gelang Rantai Emas 22K", category: "Perhiasan Emas", price: "Rp 11.200.000", status: "Aktif", image: "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=120&h=120&fit=crop&auto=format" },
  { no: 4, name: "HP Samsung Galaxy S23", category: "Elektronik", price: "Rp 7.800.000", status: "Non-aktif", image: "https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=120&h=120&fit=crop&auto=format" },
  { no: 5, name: "Antam Logam Mulia 10g", category: "Logam Mulia", price: "Rp 11.850.000", status: "Aktif", image: "https://images.unsplash.com/photo-1610375461246-83df859d849d?w=120&h=120&fit=crop&auto=format" },
];

function AdminSidebar({ active }: { active: "dashboard" | "barang" | "tambah" | "backup" | "harga" | "pembiayaan" | "pengaturan" }) {
  return (
    <aside className="flex flex-col border-r border-[#D7E7D8] bg-white px-5 py-6 text-[#212121]">
      <Link to="/admin/dashboard" className="flex min-h-[86px] items-center rounded-[24px] border border-border bg-[#F9FAFB] px-4 transition hover:border-primary/50">
        <ImageWithFallback src={pegadaianSyariahLogo} alt="Logo Pegadaian Syariah" className="h-12 w-full object-contain object-left" />
      </Link>

      <div className="mt-5 rounded-[22px] bg-secondary px-4 py-4">
        <p className="text-[12px] font-semibold uppercase tracking-[0.14em] text-[#1B5E20]">Panel Admin</p>
        <p className="mt-1 text-[15px] font-medium leading-6 text-[#1B5E20]">Database lokal CPS Simpang Patal</p>
      </div>

      <nav className="mt-6 flex flex-1 flex-col gap-2">
        <DrawerItem icon={Home} label="Ringkasan" active={active === "dashboard"} to="/admin/dashboard" />
        <DrawerItem icon={Package} label="Kelola Barang" active={active === "barang"} to="/admin/barang" />
        <DrawerItem icon={FilePlus2} label="Tambah Barang" active={active === "tambah"} to="/admin/barang/tambah" />
        <DrawerItem icon={Gem} label="Harga Emas" active={active === "harga"} to="/admin/harga-emas" />
        <DrawerItem icon={Archive} label="Backup Data" active={active === "backup"} to="/admin/backup" />
        <DrawerItem icon={ShieldCheck} label="Pembiayaan" active={active === "pembiayaan"} to="/admin/pembiayaan" />
        <DrawerItem icon={Settings} label="Pengaturan" active={active === "pengaturan"} to="/admin/pengaturan" />
      </nav>

      <Link to="/" className="flex min-h-12 items-center gap-3 rounded-2xl border border-border bg-[#F9FAFB] px-4 text-[15px] font-medium text-[#616161] transition hover:border-primary hover:text-primary">
        <LogOut className="size-5" />
        <span>Keluar ke Katalog</span>
      </Link>
    </aside>
  );
}

function AdminItemsPage() {
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);

  return (
    <main className="relative grid min-h-screen grid-cols-[20%_80%] bg-background text-foreground">
      <AdminSidebar active="barang" />
      <section className="overflow-hidden bg-[#F9FAFB] px-8 py-8">
        <header className="flex items-center justify-between">
          <div>
            <h2 className="text-[32px] font-bold leading-tight text-[#212121]">Daftar Barang Lelang</h2>
            <p className="mt-2 text-[16px] font-semibold text-[#616161]">Kelola data barang lelang pada database offline cabang.</p>
          </div>
        </header>

        <div className="mt-7 grid grid-cols-[1fr_220px_180px] gap-4 rounded-[24px] border border-border bg-white p-4">
          <div className="flex min-h-12 items-center gap-3 rounded-full border border-border bg-white px-5">
            <Search className="size-5 text-[#616161]" />
            <span className="font-semibold text-[#616161]">Cari berdasarkan nama...</span>
          </div>
          <button className="flex min-h-12 items-center justify-between rounded-full border border-border bg-white px-5 font-bold text-[#616161]">Kategori <ChevronRight className="size-4 rotate-90" /></button>
          <button className="flex min-h-12 items-center justify-between rounded-full border border-border bg-white px-5 font-bold text-[#616161]">Terbaru <ChevronRight className="size-4 rotate-90" /></button>
        </div>

        <section className="mt-7 overflow-hidden rounded-[24px] border border-border bg-white">
          <table className="w-full border-collapse text-left">
            <thead className="bg-[#F9FAFB] text-[13px] font-medium uppercase tracking-[0.06em] text-[#616161]">
              <tr>
                <th className="px-5 py-4">No</th>
                <th className="px-5 py-4">Thumbnail</th>
                <th className="px-5 py-4">Nama Barang</th>
                <th className="px-5 py-4">Kategori</th>
                <th className="px-5 py-4">Harga Dasar</th>
                <th className="px-5 py-4">Status</th>
                <th className="px-5 py-4 text-center">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {adminRows.map((row) => (
                <tr key={row.no} className="text-[15px] font-semibold text-[#212121]">
                  <td className="px-5 py-4 text-[#616161]">{row.no}</td>
                  <td className="px-5 py-4"><img src={row.image} alt={row.name} className="h-16 w-12 rounded-xl border border-border bg-[#F7F8F7] object-contain p-1" /></td>
                  <td className="px-5 py-4 font-semibold">{row.name}</td>
                  <td className="px-5 py-4 text-[#616161]">{row.category}</td>
                  <td className="px-5 py-4 font-semibold text-primary">{row.price}</td>
                  <td className="px-5 py-4"><span className={`rounded-full px-3 py-1 text-xs font-semibold ${row.status === "Aktif" ? "bg-secondary text-[#1B5E20]" : "bg-[#F5F5F5] text-[#616161]"}`}>{row.status}</span></td>
                  <td className="px-5 py-4">
                    <div className="flex justify-center gap-2">
                      <Link to="/admin/barang/edit" className="flex size-10 items-center justify-center rounded-full border border-primary bg-white text-primary transition hover:bg-secondary"><Edit3 className="size-4" /></Link>
                      <button onClick={() => setIsDeleteOpen(true)} className="flex size-10 items-center justify-center rounded-full border border-[#B71C1C] bg-white text-[#B71C1C] transition hover:bg-[#B71C1C]/10"><Trash2 className="size-4" /></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>

        {isDeleteOpen && <DeleteConfirmDialog onClose={() => setIsDeleteOpen(false)} />}

        <footer className="mt-6 flex items-center justify-between rounded-[24px] border border-border bg-white px-5 py-4">
          <p className="font-semibold text-[#616161]">Menampilkan <span className="font-semibold text-[#212121]">1-10</span> dari <span className="font-semibold text-[#212121]">42</span> barang</p>
          <div className="flex gap-3">
            <button className="min-h-11 rounded-full border border-border bg-white px-5 font-semibold text-[#616161]">Sebelumnya</button>
            <button className="min-h-11 rounded-full bg-primary px-5 font-semibold text-white">Selanjutnya</button>
          </div>
        </footer>
      </section>
    </main>
  );
}

function DeleteConfirmDialog({ onClose }: { onClose: () => void }) {
  return (
    <div className="absolute inset-0 z-30 flex items-center justify-center bg-[#F9FAFB]/78 px-8">
      <section className="w-full max-w-[560px] overflow-hidden rounded-[20px] border border-border bg-white shadow-[0_18px_48px_rgba(33,33,33,0.10)]">
        <div className="h-2 bg-[#B71C1C]" />
        <div className="px-8 pb-8 pt-9 text-center">
          <div className="mx-auto flex size-20 items-center justify-center rounded-full bg-[#B71C1C] text-white">
            <AlertTriangle className="size-10" />
          </div>
          <h2 className="mt-6 text-[28px] font-bold leading-tight text-[#212121]">Hapus Barang dari Database?</h2>
          <p className="mt-4 text-[16px] font-semibold leading-8 text-[#616161]">
            Apakah Anda yakin ingin menghapus <span className="font-semibold text-[#212121]">&quot;Cincin Emas Solitaire 18K&quot;</span>? Tindakan ini akan menghapus data dari database lokal SQLite dan menghapus semua file foto terkait dari penyimpanan tablet secara permanen.
          </p>
          <div className="mt-8 flex justify-center gap-5">
            <button onClick={onClose} className="min-h-12 w-[45%] rounded-full bg-[#EEEEEE] px-6 text-[16px] font-semibold text-[#212121]">Batal</button>
            <button onClick={onClose} className="min-h-12 w-[45%] rounded-full bg-[#B71C1C] px-6 text-[16px] font-semibold text-white">Ya, Hapus Permanen</button>
          </div>
        </div>
      </section>
    </div>
  );
}

function Field({ label, required = false, children }: { label: string; required?: boolean; children: ReactNode }) {
  return (
    <label className="block">
      <span className="text-[14px] font-medium text-[#212121]">{label}{required && <span className="ml-1 text-[#B71C1C]">*</span>}</span>
      <div className="mt-2">{children}</div>
    </label>
  );
}

const inputClass = "min-h-12 w-full rounded-[24px] border border-border bg-white px-4 text-[16px] font-semibold text-[#212121] outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10";

function AddItemPage() {
  const photos = [
    "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=180&h=180&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=180&h=180&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=180&h=180&fit=crop&auto=format",
  ];

  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="tambah" />
      <section className="flex min-h-screen flex-col bg-[#F9FAFB] px-8 py-8">
        <header>
          <h2 className="text-[32px] font-bold leading-tight text-[#212121]">Tambah Barang Lelang</h2>
          <p className="mt-2 text-[16px] font-semibold text-[#616161]">Input data barang baru ke database offline cabang.</p>
        </header>

        <div className="mt-7 grid flex-1 grid-cols-2 gap-7">
          <section className="rounded-[24px] border border-border bg-white p-6">
            <div className="grid gap-5">
              <Field label="Nama Barang" required><input className={inputClass} value="Cincin Emas Berlian" readOnly /></Field>
              <Field label="Kategori" required><div className={`${inputClass} flex items-center justify-between`}>Perhiasan Emas <ChevronRight className="size-4 rotate-90 text-[#616161]" /></div></Field>
              <div className="grid grid-cols-2 gap-4">
                <Field label="Berat (gram)" required><input className={inputClass} value="4.80" readOnly /></Field>
                <Field label="Karat (opsional)"><input className={inputClass} value="18 Karat" readOnly /></Field>
              </div>
              <Field label="Kondisi Barang" required>
                <div className="grid grid-cols-3 gap-3 rounded-2xl border border-border bg-[#F9FAFB] p-2">
                  {["Baik", "Cukup Baik", "Perlu Perbaikan"].map((condition, index) => (
                    <button key={condition} className={`min-h-11 rounded-full text-[14px] font-semibold ${index === 0 ? "bg-primary text-white" : "bg-white text-[#616161]"}`}>{condition}</button>
                  ))}
                </div>
              </Field>
              <Field label="Harga Dasar Lelang" required><input className={inputClass} value="Rp 5.500.000" readOnly /></Field>
              <Field label="Deskripsi Barang"><textarea className={`${inputClass} min-h-[128px] resize-none py-4`} value="Cincin emas dengan aksen berlian kecil, kondisi baik, warna kuning berkilau dan siap masuk katalog lelang outlet." readOnly /></Field>

              <section className="rounded-[24px] border border-[#D7E7D8] bg-[#F9FAFB] p-5">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <h3 className="text-[18px] font-bold text-[#212121]">Konfigurasi Pembiayaan per Item</h3>
                    <p className="mt-1 text-[13px] font-medium text-[#616161]">Wajib diisi jika simulasi pembiayaan aktif.</p>
                  </div>
                  <button className="rounded-full bg-primary px-4 py-2 text-[13px] font-bold text-white">Aktif</button>
                </div>
                <div className="mt-4 grid grid-cols-2 gap-4">
                  <Field label="Tipe Mu'nah" required>
                    <div className="grid grid-cols-2 gap-2 rounded-2xl border border-border bg-white p-2">
                      <button className="min-h-10 rounded-full bg-primary text-[13px] font-bold text-white">Persen</button>
                      <button className="min-h-10 rounded-full text-[13px] font-semibold text-[#616161]">Nominal</button>
                    </div>
                  </Field>
                  <Field label="Nilai Mu'nah / 10 Hari" required><input className={inputClass} value="0.38%" readOnly /></Field>
                </div>
                <div className="mt-4 rounded-2xl border border-border bg-white p-4">
                  <p className="text-[13px] font-medium text-[#616161]">Preview berdasarkan harga Rp 5.500.000 dan DP 25%</p>
                  <p className="mt-1 text-[20px] font-bold text-primary">Mu'nah per 10 hari: Rp 16.000</p>
                </div>
              </section>
            </div>
          </section>

          <section className="rounded-[24px] border border-border bg-white p-6">
            <h3 className="text-[22px] font-semibold text-[#212121]">Unggah Foto Barang <span className="text-[#616161]">(Maks 10)</span></h3>
            <div className="mt-5 flex min-h-[220px] flex-col items-center justify-center rounded-2xl border-2 border-dashed border-[#BDBDBD] bg-[#F9FAFB] px-8 text-center">
              <div className="flex size-16 items-center justify-center rounded-full bg-secondary text-primary"><CloudUpload className="size-8" /></div>
              <p className="mt-4 max-w-[360px] text-[17px] font-semibold leading-snug text-[#212121]">Ambil Foto dari Kamera / Pilih dari Galeri Tablet</p>
              <p className="mt-2 text-[14px] font-semibold text-[#616161]">Format JPG atau PNG. Foto portrait dari kamera akan ditampilkan penuh tanpa crop.</p>
            </div>

            <div className="mt-6 grid grid-cols-4 gap-4">
              {Array.from({ length: 8 }).map((_, index) => (
                <div key={index} className="relative aspect-square rounded-2xl border border-border bg-[#F9FAFB]">
                  {photos[index] && <img src={photos[index]} alt={`Preview foto ${index + 1}`} className="h-full w-full rounded-2xl object-cover p-1" />}
                  {photos[index] && (
                    <>
                      <button className="absolute -right-2 -top-2 flex size-7 items-center justify-center rounded-full bg-[#B71C1C] text-white"><X className="size-4" /></button>
                      {index === 0 && <span className="absolute bottom-2 left-2 rounded-full bg-primary px-2.5 py-1 text-[11px] font-semibold text-white">Foto Utama</span>}
                    </>
                  )}
                </div>
              ))}
            </div>
          </section>
        </div>

        <footer className="mt-7 flex justify-end gap-4">
          <Link to="/admin/barang" className="inline-flex min-h-12 items-center rounded-full bg-[#EEEEEE] px-8 text-[16px] font-semibold text-[#212121]">Batal</Link>
          <button className="min-h-12 rounded-full bg-primary px-10 text-[16px] font-semibold text-white">Simpan ke Database</button>
        </footer>
      </section>
    </main>
  );
}

function BackupPage() {
  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="backup" />
      <section className="bg-[#F9FAFB] px-8 py-8">
        <header>
          <h2 className="text-[32px] font-bold leading-tight text-[#212121]">Backup &amp; Ekspor Database Lokal</h2>
          <p className="mt-2 text-[16px] font-semibold text-[#616161]">Ekspor database SQLite dan foto ke penyimpanan luar (USB/SD Card)</p>
        </header>

        <section className="mt-7 rounded-[24px] border border-border bg-white p-6 shadow-[0_6px_18px_rgba(33,33,33,0.025)]">
          <div className="flex items-center gap-4">
            <div className="flex size-14 items-center justify-center rounded-2xl bg-secondary text-primary"><Database className="size-7" /></div>
            <div>
              <h3 className="text-[20px] font-bold text-[#212121]">Database Saat Ini</h3>
              <p className="mt-1 text-[16px] font-semibold text-[#616161]">42 Barang, 120 Foto, Ukuran: 18.4 MB. Terakhir di-backup: Kemarin, 17:00</p>
            </div>
          </div>
        </section>

        <div className="mt-7 grid grid-cols-2 gap-7">
          <article className="rounded-[24px] border border-border bg-white p-6">
            <div className="flex items-start justify-between">
              <div>
                <div className="flex size-14 items-center justify-center rounded-2xl bg-secondary text-primary"><HardDrive className="size-7" /></div>
                <h3 className="mt-5 text-[24px] font-bold text-[#212121]">Ekspor ke USB OTG Drive</h3>
                <p className="mt-2 text-[15px] font-semibold leading-7 text-[#616161]">Pilih drive eksternal yang terhubung ke tablet kiosk.</p>
              </div>
            </div>
            <button className="mt-6 flex min-h-12 w-full items-center justify-between rounded-full border border-border bg-white px-5 text-[16px] font-bold text-[#616161]">USB_DRIVE_01 / PegadaianBackup <ChevronRight className="size-4 rotate-90" /></button>
            <button className="mt-4 min-h-12 w-full rounded-full bg-primary px-6 text-[16px] font-semibold text-white">Mulai Ekspor</button>
          </article>

          <article className="rounded-[24px] border border-border bg-white p-6">
            <div className="flex size-14 items-center justify-center rounded-2xl bg-secondary text-primary"><Folder className="size-7" /></div>
            <h3 className="mt-5 text-[24px] font-bold text-[#212121]">Ekspor ke Folder Dokumen Tablet</h3>
            <p className="mt-2 text-[15px] font-semibold leading-7 text-[#616161]">Simpan salinan database dan foto pada folder lokal perangkat.</p>
            <button className="mt-[92px] min-h-12 w-full rounded-full border border-primary bg-white px-6 text-[16px] font-semibold text-primary">Simpan ke Folder Lokal</button>
          </article>
        </div>

        <div className="mt-7 grid grid-cols-[1fr_360px] gap-7">
          <section className="rounded-[24px] border border-border bg-white p-6">
            <div className="flex items-center justify-between">
              <h3 className="text-[20px] font-bold text-[#212121]">Sedang menyalin database... <span className="text-primary">65%</span></h3>
              <button className="min-h-10 rounded-full border border-[#B71C1C] bg-white px-5 text-[14px] font-semibold text-[#B71C1C]">Batalkan</button>
            </div>
            <div className="mt-5 h-4 overflow-hidden rounded-full bg-secondary">
              <div className="h-full w-[65%] rounded-full bg-primary" />
            </div>
            <p className="mt-3 text-[14px] font-semibold text-[#616161]">Menyalin foto barang dan file katalog SQLite ke tujuan backup.</p>
          </section>

          <aside className="rounded-2xl border border-primary/30 bg-white p-6">
            <div className="flex items-start gap-4">
              <div className="flex size-14 shrink-0 items-center justify-center rounded-full bg-secondary text-primary"><CheckCircle2 className="size-8" /></div>
              <div>
                <h3 className="text-[20px] font-bold text-[#212121]">Ekspor Berhasil!</h3>
                <p className="mt-2 text-[15px] font-semibold leading-7 text-[#616161]">File saved as <span className="font-semibold text-[#1B5E20]">katalog_backup_2025_06_19.db</span></p>
              </div>
            </div>
          </aside>
        </div>
      </section>
    </main>
  );
}

function GoldPriceAdminPage() {
  const [goldPrice, setGoldPrice] = useGoldPricePerGram();
  const [draft, setDraft] = useState(formatRupiah(goldPrice));

  useEffect(() => {
    setDraft(formatRupiah(goldPrice));
  }, [goldPrice]);

  function savePrice() {
    const numericValue = Number(draft.replace(/[^0-9]/g, ""));
    if (!numericValue) return;
    window.localStorage.setItem("pegadaian_gold_price_per_gram", String(numericValue));
    setGoldPrice(numericValue);
    setDraft(formatRupiah(numericValue));
  }

  const examples = items.filter((item) => item.gram).slice(0, 3);

  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="harga" />
      <section className="bg-[#F9FAFB] px-8 py-8">
        <header>
          <h2 className="text-[32px] font-bold leading-tight text-[#212121]">Update Harga Emas Hari Ini</h2>
          <p className="mt-2 text-[16px] font-semibold text-[#616161]">Harga barang kategori emas di katalog otomatis mengikuti harga per gram yang tersimpan.</p>
        </header>

        <div className="mt-7 grid grid-cols-[1fr_1.1fr] gap-7">
          <section className="rounded-[24px] border border-border bg-white p-7">
            <div className="flex size-16 items-center justify-center rounded-2xl bg-secondary text-primary"><Gem className="size-8" /></div>
            <h3 className="mt-5 text-[24px] font-bold text-[#212121]">Harga Emas per Gram</h3>
            <p className="mt-2 text-[15px] font-semibold leading-7 text-[#616161]">Masukkan harga emas terbaru untuk simulasi harga dasar lelang pada seluruh barang emas.</p>

            <label className="mt-7 block">
              <span className="text-[14px] font-semibold text-[#212121]">Harga Hari Ini <span className="text-[#B71C1C]">*</span></span>
              <input value={draft} onChange={(event) => setDraft(event.target.value)} className="mt-2 min-h-16 w-full rounded-[24px] border border-border bg-white px-5 text-[28px] font-bold text-primary outline-none focus:border-primary focus:ring-2 focus:ring-primary/10" />
            </label>

            <div className="mt-6 rounded-2xl border border-border bg-[#F9FAFB] p-4 text-[14px] font-semibold leading-7 text-[#616161]">
              Contoh: jika harga emas diinput <span className="font-bold text-[#212121]">{formatRupiah(goldPrice)}</span>, maka barang emas 10.5 gram otomatis menjadi <span className="font-bold text-primary">{formatRupiah(10.5 * goldPrice)}</span>.
            </div>

            <button onClick={savePrice} className="mt-6 min-h-12 w-full rounded-full bg-primary px-8 text-[16px] font-bold text-white">Simpan & Terapkan ke Katalog</button>
          </section>

          <section className="rounded-[24px] border border-border bg-white p-7">
            <div className="flex items-center justify-between border-b border-border pb-4">
              <h3 className="text-[22px] font-bold text-[#212121]">Preview Harga Katalog</h3>
              <span className="rounded-full bg-secondary px-4 py-2 text-[13px] font-bold text-[#1B5E20]">Otomatis</span>
            </div>
            <div className="divide-y divide-border">
              {examples.map((item) => (
                <div key={item.name} className="grid grid-cols-[1fr_auto] gap-4 py-5">
                  <div>
                    <p className="text-[17px] font-bold text-[#212121]">{item.name}</p>
                    <p className="mt-1 text-[14px] font-semibold text-[#616161]">Berat {item.gram?.toFixed(2)} gram × {formatRupiah(goldPrice)}</p>
                  </div>
                  <p className="text-[22px] font-bold text-primary">{getDisplayPrice(item, goldPrice)}</p>
                </div>
              ))}
            </div>
            <p className="mt-5 rounded-2xl bg-[#FFF8E1] p-4 text-[14px] font-semibold leading-7 text-[#8A5A00]">Perubahan harga tersimpan lokal di tablet dan digunakan oleh halaman katalog serta detail barang emas.</p>
          </section>
        </div>
      </section>
    </main>
  );
}

function EditItemPage() {
  const photos = [
    "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=180&h=180&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=180&h=180&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=180&h=180&fit=crop&auto=format",
  ];

  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="barang" />
      <section className="flex min-h-screen flex-col bg-[#F9FAFB] px-8 py-8">
        <header className="flex items-center justify-between">
          <div>
            <h2 className="text-[32px] font-bold leading-tight text-[#212121]">B1 Edit Barang</h2>
            <p className="mt-2 text-[16px] font-semibold text-[#616161]">Perbarui informasi barang lelang di database cabang.</p>
          </div>
          <div className="flex gap-3">
            <button className="flex min-h-12 items-center gap-2 rounded-full border border-[#B71C1C] bg-white px-5 text-[15px] font-bold text-[#B71C1C] transition hover:bg-[#B71C1C] hover:text-white">
              <Trash2 className="size-5" />
              Hapus Barang
            </button>
          </div>
        </header>

        <div className="mt-7 grid flex-1 grid-cols-2 gap-7">
          <section className="rounded-[24px] border border-border bg-white p-6 shadow-sm">
            <div className="grid gap-5">
              <Field label="Nama Barang" required><input className={inputClass} defaultValue="Gelang Rantai Emas 22K 10.5g" /></Field>
              <Field label="Kategori" required><div className={`${inputClass} flex items-center justify-between`}>Perhiasan Emas <ChevronRight className="size-4 rotate-90 text-[#616161]" /></div></Field>
              <div className="grid grid-cols-2 gap-4">
                <Field label="Berat (gram)" required><input className={inputClass} defaultValue="10.50" /></Field>
                <Field label="Karat (opsional)"><input className={inputClass} defaultValue="22 Karat" /></Field>
              </div>
              <Field label="Kondisi Barang" required>
                <div className="grid grid-cols-3 gap-3 rounded-2xl border border-border bg-[#F9FAFB] p-2">
                  {["Sangat Baik", "Baik", "Cukup"].map((condition, index) => (
                    <button key={condition} className={`min-h-11 rounded-full text-[14px] font-semibold ${index === 0 ? "bg-primary text-white shadow-sm" : "bg-white text-[#616161]"}`}>{condition}</button>
                  ))}
                </div>
              </Field>
              <Field label="Harga Dasar Lelang" required><input className={inputClass} defaultValue="Rp 11.200.000" /></Field>
              <Field label="Deskripsi Barang"><textarea className={`${inputClass} min-h-[128px] resize-none py-4`} defaultValue="Gelang emas model rantai dengan pengunci kokoh, warna kuning berkilau alami, kondisi terawat tanpa cacat fisik." /></Field>

              <section className="rounded-[24px] border border-[#D7E7D8] bg-[#F1F8F1] p-5">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <h3 className="text-[18px] font-bold text-[#1B5E20]">Konfigurasi Pembiayaan</h3>
                    <p className="mt-1 text-[13px] font-medium text-[#1B5E20]/70">Simulasi cicilan untuk barang ini.</p>
                  </div>
                  <div className="flex h-8 items-center rounded-full bg-[#00AA13] px-3 text-[12px] font-bold text-white">AKTIF</div>
                </div>
                <div className="mt-4 grid grid-cols-2 gap-4">
                  <Field label="Tipe Mu'nah"><div className="flex h-12 items-center justify-center rounded-full bg-white font-bold text-[#212121]">Persentase (%)</div></Field>
                  <Field label="Nilai Mu'nah"><input className={inputClass} defaultValue="0.38%" /></Field>
                </div>
              </section>
            </div>
          </section>

          <section className="rounded-[24px] border border-border bg-white p-6 shadow-sm">
            <h3 className="text-[22px] font-bold text-[#212121]">Galeri Foto Barang</h3>
            <p className="mt-1 text-[15px] font-medium text-[#616161]">Foto pertama akan menjadi sampul utama.</p>
            
            <div className="mt-6 grid grid-cols-4 gap-4">
              {Array.from({ length: 8 }).map((_, index) => (
                <div key={index} className="group relative aspect-square rounded-2xl border border-border bg-[#F9FAFB] transition hover:border-primary/50">
                  {photos[index] ? (
                    <>
                      <img src={photos[index]} alt={`Foto ${index + 1}`} className="h-full w-full rounded-2xl object-cover p-1" />
                      <button className="absolute -right-2 -top-2 flex size-7 items-center justify-center rounded-full bg-[#B71C1C] text-white opacity-0 shadow-lg transition group-hover:opacity-100"><X className="size-4" /></button>
                      {index === 0 && <span className="absolute bottom-2 left-2 rounded-full bg-[#00AA13] px-2.5 py-1 text-[10px] font-bold text-white uppercase tracking-wider">Utama</span>}
                    </>
                  ) : (
                    <div className="flex h-full w-full flex-col items-center justify-center gap-1 text-[#9E9E9E]">
                      <Plus className="size-6" />
                      <span className="text-[11px] font-bold uppercase tracking-wider">Tambah</span>
                    </div>
                  )}
                </div>
              ))}
            </div>

            <div className="mt-8 rounded-2xl bg-[#E8F5E9]/50 p-6 text-center border-2 border-dashed border-[#00AA13]/30">
              <CloudUpload className="mx-auto size-10 text-[#00AA13]" />
              <p className="mt-3 text-[17px] font-bold text-[#1B5E20]">Ambil Foto Baru</p>
              <p className="mt-1 text-[14px] font-medium text-[#1B5E20]/70">Gunakan kamera tablet untuk memotret barang.</p>
            </div>
            
            <div className="mt-8 grid grid-cols-2 gap-4">
              <div className="rounded-2xl border border-border bg-[#F9FAFB] p-4">
                <p className="text-[13px] font-semibold text-[#616161]">ID Database</p>
                <p className="mt-1 text-[18px] font-bold text-[#212121]">#LGN-0042</p>
              </div>
              <div className="rounded-2xl border border-border bg-[#F9FAFB] p-4">
                <p className="text-[13px] font-semibold text-[#616161]">Terakhir Diubah</p>
                <p className="mt-1 text-[18px] font-bold text-[#212121]">19 Jun 2025</p>
              </div>
            </div>
          </section>
        </div>

        <footer className="mt-7 flex justify-end gap-4">
          <Link to="/admin/barang" className="inline-flex min-h-14 items-center rounded-full border border-[#D2D2D2] bg-white px-9 text-[17px] font-bold text-[#616161] transition hover:bg-[#F5F5F5]">Batal</Link>
          <button 
            onClick={() => toast.success("Data barang berhasil diperbarui ke database lokal!")}
            className="min-h-14 rounded-full bg-[#00AA13] px-12 text-[18px] font-bold text-white shadow-lg transition hover:bg-[#009110] active:scale-95"
          >
            Perbarui Data
          </button>
        </footer>
      </section>
    </main>
  );
}

function FinancingConfigAdminPage() {
  const config = mockItemFinancingConfig;
  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="pembiayaan" />
      <section className="bg-[#F9FAFB] px-8 py-8">
        <header className="flex items-start justify-between">
          <div>
            <h2 className="max-w-5xl text-[32px] font-bold leading-tight text-[#212121]">Konfigurasi Pembiayaan Syariah</h2>
            <p className="mt-2 text-[16px] font-medium text-[#616161]">Mock konfigurasi ini disiapkan agar mudah diganti dengan data SQLite outlet.</p>
          </div>
          <div className="rounded-full bg-secondary px-5 py-3 text-[15px] font-semibold text-[#1B5E20]">Aturan aktif</div>
        </header>

        <div className="mt-7 grid grid-flow-dense grid-cols-2 gap-6">
          <section className="rounded-[24px] border border-border bg-white p-6 shadow-[0_10px_28px_rgba(33,33,33,0.035)]">
            <h3 className="text-[22px] font-bold text-[#212121]">Parameter Utama</h3>
            <div className="mt-5 grid grid-cols-2 gap-4">
              {[
                ["Pilihan DP", config.dpPercentOptions.map((value) => `${value}%`).join(", ")],
                ["Biaya admin flat", formatRupiah(config.adminFeeFlat)],
                ["Biaya admin persen", `${config.adminFeePercent}%`],
                ["Mu'nah per 10 hari", config.munahInputType === "percent" ? `${config.munahValuePer10Days}%` : formatRupiah(config.munahValuePer10Days)],
              ].map(([label, value]) => (
                <div key={label} className="rounded-2xl border border-border bg-[#F9FAFB] p-4">
                  <p className="text-[13px] font-medium text-[#616161]">{label}</p>
                  <p className="mt-1 text-[22px] font-bold text-[#212121]">{value}</p>
                </div>
              ))}
            </div>
          </section>

          <section className="rounded-[24px] border border-border bg-white p-6 shadow-[0_10px_28px_rgba(33,33,33,0.035)]">
            <h3 className="text-[22px] font-bold text-[#212121]">Tenor dan Biaya Lain</h3>
            <div className="mt-5 flex flex-wrap gap-3">
              {config.tenorMonths.map((month) => <span key={month} className="rounded-full bg-primary px-5 py-3 text-[16px] font-bold text-white">{month} bulan</span>)}
            </div>
            <div className="mt-6 grid grid-cols-3 gap-4">
              <div className="rounded-2xl bg-[#F9FAFB] p-4"><p className="text-[13px] font-medium text-[#616161]">Status</p><p className="mt-1 text-[18px] font-bold">{config.financingEnabled ? "Aktif" : "Nonaktif"}</p></div>
              <div className="rounded-2xl bg-[#F9FAFB] p-4"><p className="text-[13px] font-medium text-[#616161]">Basis</p><p className="mt-1 text-[18px] font-bold">Per 10 hari</p></div>
              <div className="rounded-2xl bg-[#F9FAFB] p-4"><p className="text-[13px] font-medium text-[#616161]">Biaya Lain</p><p className="mt-1 text-[18px] font-bold">{formatRupiah(config.otherFee)}</p></div>
            </div>
          </section>
        </div>

        <footer className="mt-7 flex justify-end gap-4 rounded-[24px] border border-border bg-white p-5">
          <button className="min-h-12 rounded-full border border-primary bg-white px-8 text-[16px] font-semibold text-primary">Nonaktifkan Aturan</button>
          <button className="min-h-12 rounded-full bg-primary px-8 text-[16px] font-bold text-white">Simpan Konfigurasi</button>
        </footer>
      </section>
    </main>
  );
}

function ToggleRow({ title, description, active = true }: { title: string; description: string; active?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-5 rounded-[20px] border border-border bg-[#F9FAFB] p-4">
      <div>
        <p className="text-[16px] font-semibold text-[#212121]">{title}</p>
        <p className="mt-1 text-[13px] font-medium leading-6 text-[#616161]">{description}</p>
      </div>
      <button className={`flex h-8 w-14 items-center rounded-full p-1 transition ${active ? "justify-end bg-primary" : "justify-start bg-[#D9D9D9]"}`}>
        <span className="size-6 rounded-full bg-white shadow-[0_2px_8px_rgba(33,33,33,0.16)]" />
      </button>
    </div>
  );
}

function SettingField({ label, value }: { label: string; value: string }) {
  return (
    <label className="block">
      <span className="text-[14px] font-semibold text-[#616161]">{label}</span>
      <div className="mt-2 flex min-h-12 items-center rounded-2xl border border-border bg-[#F9FAFB] px-4 text-[16px] font-semibold text-[#212121]">{value}</div>
    </label>
  );
}

function SettingsPage() {
  return (
    <main className="grid min-h-screen grid-cols-[20%_80%] bg-[#F9FAFB] text-foreground">
      <AdminSidebar active="pengaturan" />
      <section className="bg-[#F9FAFB] px-8 py-8">
        <header className="flex items-start justify-between">
          <div>
            <h2 className="max-w-5xl text-[32px] font-bold leading-tight text-[#212121]">Pengaturan Aplikasi</h2>
            <p className="mt-2 text-[16px] font-medium text-[#616161]">Atur identitas outlet, mode kiosk, keamanan admin, dan preferensi tampilan katalog.</p>
          </div>
          <div className="rounded-full bg-white px-5 py-3 text-[15px] font-semibold text-primary shadow-[0_8px_22px_rgba(33,33,33,0.05)]">SQLite lokal aktif</div>
        </header>

        <div className="mt-7 grid grid-flow-dense grid-cols-2 gap-6">
          <section className="rounded-[28px] border border-border bg-white p-6 shadow-[0_12px_30px_rgba(33,33,33,0.04)]">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="text-[22px] font-bold text-[#212121]">Identitas Outlet</h3>
                <p className="mt-1 text-[14px] font-medium text-[#616161]">Informasi yang tampil pada header kiosk.</p>
              </div>
              <div className="rounded-full bg-secondary px-4 py-2 text-[13px] font-semibold text-[#1B5E20]">Publik</div>
            </div>
            <div className="mt-5 grid grid-cols-2 gap-4">
              <SettingField label="Nama Cabang" value="Cabang Simpang Patal" />
              <SettingField label="Kode Outlet" value="CPS-SPT-001" />
              <SettingField label="Jenis Unit" value="Cabang Pelayanan Syariah" />
              <SettingField label="Zona Waktu" value="WIB / Palembang" />
            </div>
          </section>

          <section className="rounded-[28px] border border-border bg-white p-6 shadow-[0_12px_30px_rgba(33,33,33,0.04)]">
            <h3 className="text-[22px] font-bold text-[#212121]">Mode Kiosk</h3>
            <p className="mt-1 text-[14px] font-medium text-[#616161]">Kontrol pengalaman layar tablet untuk pengunjung.</p>
            <div className="mt-5 grid gap-3">
              <ToggleRow title="Sembunyikan navigasi sistem" description="Menjaga pengunjung tetap berada di aplikasi katalog." />
              <ToggleRow title="Tampilkan jam lokal" description="Jam outlet tetap terlihat pada header publik." />
              <ToggleRow title="Reset otomatis saat idle" description="Kembali ke katalog utama setelah tidak aktif." />
            </div>
          </section>

          <section className="rounded-[28px] border border-border bg-white p-6 shadow-[0_12px_30px_rgba(33,33,33,0.04)]">
            <h3 className="text-[22px] font-bold text-[#212121]">Keamanan Admin</h3>
            <p className="mt-1 text-[14px] font-medium text-[#616161]">Pengaturan akses panel admin cabang.</p>
            <div className="mt-5 grid gap-4">
              <SettingField label="Panjang PIN" value="6 digit" />
              <SettingField label="Percobaan Maksimum" value="5 kali" />
              <ToggleRow title="Kunci otomatis panel admin" description="Keluar dari admin setelah tidak aktif selama 5 menit." />
            </div>
          </section>

          <section className="rounded-[28px] border border-border bg-white p-6 shadow-[0_12px_30px_rgba(33,33,33,0.04)]">
            <h3 className="text-[22px] font-bold text-[#212121]">Preferensi Katalog</h3>
            <p className="mt-1 text-[14px] font-medium text-[#616161]">Atur tampilan kartu barang dan data yang terlihat.</p>
            <div className="mt-5 grid gap-3">
              <ToggleRow title="Tampilkan simulasi pembiayaan" description="CTA pembiayaan muncul pada halaman detail barang." />
              <ToggleRow title="Tampilkan harga emas harian" description="Harga emas per gram tampil pada halaman katalog." />
              <ToggleRow title="Badge kategori berwarna" description="Kategori lebih mudah dibedakan oleh pengunjung." />
            </div>
          </section>
        </div>

        <section className="mt-7 rounded-[28px] border border-[#D7E7D8] bg-white p-6 shadow-[0_12px_30px_rgba(33,33,33,0.035)]">
          <div className="grid items-center gap-6 lg:grid-cols-[1fr_auto]">
            <div>
              <h3 className="text-[22px] font-bold text-[#212121]">Status Sistem Lokal</h3>
              <p className="mt-2 text-[15px] font-medium leading-7 text-[#616161]">Database SQLite, folder foto lokal, dan konfigurasi kiosk siap digunakan. Perubahan pengaturan disimpan di perangkat tablet cabang.</p>
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div className="rounded-2xl bg-secondary px-5 py-4 text-center"><p className="text-[13px] font-medium text-[#1B5E20]">Database</p><p className="mt-1 text-[18px] font-bold text-[#1B5E20]">Aktif</p></div>
              <div className="rounded-2xl bg-[#FFF8E1] px-5 py-4 text-center"><p className="text-[13px] font-medium text-[#8A5A00]">Backup</p><p className="mt-1 text-[18px] font-bold text-[#8A5A00]">Kemarin</p></div>
              <div className="rounded-2xl bg-[#E3F2FD] px-5 py-4 text-center"><p className="text-[13px] font-medium text-[#0D47A1]">Versi</p><p className="mt-1 text-[18px] font-bold text-[#0D47A1]">1.0.0</p></div>
            </div>
          </div>
        </section>

        <footer className="mt-7 flex justify-end gap-4 rounded-[24px] border border-border bg-white p-5">
          <button className="min-h-12 rounded-full border border-primary bg-white px-8 text-[16px] font-semibold text-primary">Batalkan</button>
          <button onClick={() => toast.success("Pengaturan aplikasi berhasil disimpan")} className="min-h-12 rounded-full bg-primary px-8 text-[16px] font-bold text-white shadow-[0_10px_24px_rgba(0,170,19,0.18)]">Simpan Pengaturan</button>
        </footer>
      </section>
    </main>
  );
}

function NotFoundPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-background p-10 text-center">
      <div className="rounded-[24px] border border-border bg-white p-10">
        <h1 className="text-3xl font-extrabold text-[#212121]">Halaman tidak ditemukan</h1>
        <Link to="/" className="mt-6 inline-flex min-h-12 items-center rounded-full bg-primary px-6 font-bold text-white">Kembali ke Katalog</Link>
      </div>
    </main>
  );
}

export const router = createBrowserRouter([
  { path: "/", Component: CatalogPage },
  { path: "/pencarian-kosong", Component: EmptySearchPage },
  { path: "/barang/gelang-rantai-emas", Component: DetailPage },
  { path: "/admin", Component: AdminPinPage },
  { path: "/admin/dashboard", Component: AdminDashboardPage },
  { path: "/admin/barang", Component: AdminItemsPage },
  { path: "/admin/barang/tambah", Component: AddItemPage },
  { path: "/admin/barang/edit", Component: EditItemPage },
  { path: "/admin/backup", Component: BackupPage },
  { path: "/admin/harga-emas", Component: GoldPriceAdminPage },
  { path: "/admin/pembiayaan", Component: FinancingConfigAdminPage },
  { path: "/admin/pengaturan", Component: SettingsPage },
  { path: "*", Component: NotFoundPage },
]);

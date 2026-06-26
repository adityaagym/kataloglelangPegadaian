export type MunahInputType = "percent" | "nominal";

export type ItemFinancingConfig = {
  hargaBarang: number;
  munahInputType: MunahInputType;
  munahValuePer10Days: number;
  adminFeeFlat: number;
  adminFeePercent: number;
  otherFee: number;
  tenorMonths: number[];
  dpPercentOptions: number[];
  financingEnabled: boolean;
};

export type FinancingResult = {
  hargaBarang: number;
  dpPercent: number;
  dpNominal: number;
  pokokPembiayaan: number;
  tenorMonths: number;
  totalHariMunah: number;
  jumlahPeriodeMunah: number;
  munahPer10Days: number;
  totalMunah: number;
  biayaAdministrasi: number;
  biayaLain: number;
  totalKewajiban: number;
  estimasiAngsuranPerBulan: number;
};

export const mockItemFinancingConfig: ItemFinancingConfig = {
  hargaBarang: 11200000,
  munahInputType: "percent",
  munahValuePer10Days: 0.38,
  adminFeeFlat: 50000,
  adminFeePercent: 0,
  otherFee: 35000,
  tenorMonths: [6, 12, 18, 24, 36],
  dpPercentOptions: [15, 25, 35, 50],
  financingEnabled: true,
};

export function calculateFinancingByItemConfig(
  hargaBarang: number,
  dpPercent: number,
  tenorMonths: number,
  config: ItemFinancingConfig,
): FinancingResult {
  const dpNominal = hargaBarang * (dpPercent / 100);
  const pokokPembiayaan = Math.max(hargaBarang - dpNominal, 0);
  const totalHariMunah = tenorMonths * 30;
  const jumlahPeriodeMunah = totalHariMunah / 10;
  const munahPer10Days = config.munahInputType === "percent"
    ? pokokPembiayaan * (config.munahValuePer10Days / 100)
    : config.munahValuePer10Days;
  const totalMunah = munahPer10Days * jumlahPeriodeMunah;
  const biayaAdministrasi = config.adminFeeFlat + pokokPembiayaan * (config.adminFeePercent / 100);
  const biayaLain = config.otherFee;
  const totalKewajiban = pokokPembiayaan + totalMunah + biayaAdministrasi + biayaLain;
  const estimasiAngsuranPerBulan = totalKewajiban / tenorMonths;

  return {
    hargaBarang,
    dpPercent,
    dpNominal,
    pokokPembiayaan,
    tenorMonths,
    totalHariMunah,
    jumlahPeriodeMunah,
    munahPer10Days,
    totalMunah,
    biayaAdministrasi,
    biayaLain,
    totalKewajiban,
    estimasiAngsuranPerBulan,
  };
}

/// Türkiye gübre fiyatları — TZOB / Tarım Bakanlığı aylık bülten referansı.
/// Public API yok; elle güncellenir. Son güncelleme altında görünür.
library;

class FertilizerPrice {
  final String name;
  final String unit;
  final double tryPrice;
  const FertilizerPrice(this.name, this.unit, this.tryPrice);
}

/// Kaynak: TZOB & yerel bayi ortalamaları (Nisan 2026).
const List<FertilizerPrice> fertilizerPrices = [
  FertilizerPrice('DAP (18-46-0)', '50 kg çuval', 2850),
  FertilizerPrice('Üre (%46 N)', '50 kg çuval', 1950),
  FertilizerPrice('Amonyum Sülfat', '50 kg çuval', 1400),
  FertilizerPrice('NPK 15-15-15', '50 kg çuval', 2100),
  FertilizerPrice('CAN (%26 N)', '50 kg çuval', 1250),
];

/// Son elle güncelleme tarihi — UI'da kullanıcıya gösterilir.
const String fertilizerPricesUpdatedAt = '2026-04-20';

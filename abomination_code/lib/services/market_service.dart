class MarketService {
  static const Map<String, int> _baseBuyPrices = {
    'wood': 5,
    'meat': 8,
    'eggs': 2,
    'cabbage': 3,
    'grain': 4,
    'ale': 15,
    'spirits': 45,
    'timber': 25,
  };

  static const Map<String, int> _baseSellPrices = {
    'wood': 3,
    'meat': 5,
    'eggs': 1,
    'cabbage': 2,
    'grain': 2,
    'ale': 10,
    'spirits': 30,
    'timber': 15,
  };

  int getBuyPrice(String resource) => _baseBuyPrices[resource] ?? 999;
  int getSellPrice(String resource) => _baseSellPrices[resource] ?? 0;

  // Future: Dynamic price fluctuations based on war events or canton mood
}

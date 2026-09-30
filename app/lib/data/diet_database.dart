/// Small, transparent Indian-food reference for the offline nutrition screen.
///
/// Values are approximate per 100 g and prices are planning estimates, not
/// medical or shopping advice. Brands, cooking method and Delhi prices vary.
/// Keep the database honest and expand it only when a source and serving size
/// are recorded. This file is Dart (not a Python data dump) so the app can
/// compile even when the diet screen is not opened.
library;

class FoodItem {
  final String name;
  final String hindi;
  final String category;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double caloriesPer100g;
  final int defaultPortionGrams;
  final double estimatedPriceInr;
  final String unitReference;

  const FoodItem({
    required this.name,
    required this.hindi,
    required this.category,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.caloriesPer100g,
    required this.defaultPortionGrams,
    required this.estimatedPriceInr,
    required this.unitReference,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'hindi': hindi,
    'category': category,
    'per100g': {
      'protein': proteinPer100g,
      'carbs': carbsPer100g,
      'fat': fatPer100g,
      'calories': caloriesPer100g,
    },
    'portionGrams': defaultPortionGrams,
    'estimatedPriceInr': estimatedPriceInr,
    'unitReference': unitReference,
  };
}

/// A deliberately modest offline catalog. The app should not present made-up
/// prices as exact facts; these are labels to help a beginner compare foods.
const foodDb = <FoodItem>[
  FoodItem(
    name: 'Egg, whole',
    hindi: 'अंडा',
    category: 'protein',
    proteinPer100g: 13,
    carbsPer100g: 1.1,
    fatPer100g: 11,
    caloriesPer100g: 155,
    defaultPortionGrams: 50,
    estimatedPriceInr: 6,
    unitReference: '1 egg',
  ),
  FoodItem(
    name: 'Chicken breast, cooked',
    hindi: 'चिकन ब्रेस्ट',
    category: 'protein',
    proteinPer100g: 31,
    carbsPer100g: 0,
    fatPer100g: 3.6,
    caloriesPer100g: 165,
    defaultPortionGrams: 150,
    estimatedPriceInr: 120,
    unitReference: '150 g cooked',
  ),
  FoodItem(
    name: 'Chicken leg, cooked',
    hindi: 'चिकन लेग',
    category: 'protein',
    proteinPer100g: 26,
    carbsPer100g: 0,
    fatPer100g: 10,
    caloriesPer100g: 205,
    defaultPortionGrams: 200,
    estimatedPriceInr: 100,
    unitReference: '200 g cooked',
  ),
  FoodItem(
    name: 'Rohu or katla fish',
    hindi: 'रोहू / कतला',
    category: 'protein',
    proteinPer100g: 22,
    carbsPer100g: 0,
    fatPer100g: 4.5,
    caloriesPer100g: 130,
    defaultPortionGrams: 150,
    estimatedPriceInr: 30,
    unitReference: '150 g',
  ),
  FoodItem(
    name: 'Paneer',
    hindi: 'पनीर',
    category: 'dairy',
    proteinPer100g: 18,
    carbsPer100g: 3.4,
    fatPer100g: 20,
    caloriesPer100g: 265,
    defaultPortionGrams: 100,
    estimatedPriceInr: 40,
    unitReference: '100 g',
  ),
  FoodItem(
    name: 'Milk, toned',
    hindi: 'टोंड दूध',
    category: 'dairy',
    proteinPer100g: 3.2,
    carbsPer100g: 4.7,
    fatPer100g: 1.5,
    caloriesPer100g: 42,
    defaultPortionGrams: 240,
    estimatedPriceInr: 12,
    unitReference: '1 cup',
  ),
  FoodItem(
    name: 'Curd / dahi',
    hindi: 'दही',
    category: 'dairy',
    proteinPer100g: 3.8,
    carbsPer100g: 4.7,
    fatPer100g: 3.3,
    caloriesPer100g: 61,
    defaultPortionGrams: 200,
    estimatedPriceInr: 15,
    unitReference: '1 bowl',
  ),
  FoodItem(
    name: 'Soy chunks, dry',
    hindi: 'सोया चंक्स',
    category: 'protein',
    proteinPer100g: 50,
    carbsPer100g: 30,
    fatPer100g: 1.5,
    caloriesPer100g: 345,
    defaultPortionGrams: 30,
    estimatedPriceInr: 12,
    unitReference: '30 g dry',
  ),
  FoodItem(
    name: 'Soybean, dry',
    hindi: 'सोयाबीन',
    category: 'legume',
    proteinPer100g: 36.5,
    carbsPer100g: 30,
    fatPer100g: 18,
    caloriesPer100g: 446,
    defaultPortionGrams: 50,
    estimatedPriceInr: 10,
    unitReference: '50 g dry',
  ),
  FoodItem(
    name: 'Masoor dal, cooked',
    hindi: 'मसूर दाल',
    category: 'legume',
    proteinPer100g: 9,
    carbsPer100g: 20,
    fatPer100g: 0.5,
    caloriesPer100g: 116,
    defaultPortionGrams: 200,
    estimatedPriceInr: 24,
    unitReference: '1 cup cooked',
  ),
  FoodItem(
    name: 'Moong dal, cooked',
    hindi: 'मूंग दाल',
    category: 'legume',
    proteinPer100g: 7,
    carbsPer100g: 18,
    fatPer100g: 0.5,
    caloriesPer100g: 105,
    defaultPortionGrams: 200,
    estimatedPriceInr: 20,
    unitReference: '1 cup cooked',
  ),
  FoodItem(
    name: 'Chana, cooked',
    hindi: 'चना',
    category: 'legume',
    proteinPer100g: 9,
    carbsPer100g: 27,
    fatPer100g: 2.6,
    caloriesPer100g: 164,
    defaultPortionGrams: 160,
    estimatedPriceInr: 15,
    unitReference: '1 cup cooked',
  ),
  FoodItem(
    name: 'Rajma, cooked',
    hindi: 'राजमा',
    category: 'legume',
    proteinPer100g: 8.5,
    carbsPer100g: 22,
    fatPer100g: 1.5,
    caloriesPer100g: 127,
    defaultPortionGrams: 200,
    estimatedPriceInr: 35,
    unitReference: '1 cup cooked',
  ),
  FoodItem(
    name: 'Wheat roti',
    hindi: 'गेहूं की रोटी',
    category: 'carb',
    proteinPer100g: 9,
    carbsPer100g: 48,
    fatPer100g: 1.5,
    caloriesPer100g: 297,
    defaultPortionGrams: 30,
    estimatedPriceInr: 2,
    unitReference: '1 roti',
  ),
  FoodItem(
    name: 'Rice, cooked',
    hindi: 'चावल',
    category: 'carb',
    proteinPer100g: 2.7,
    carbsPer100g: 28,
    fatPer100g: 0.3,
    caloriesPer100g: 130,
    defaultPortionGrams: 150,
    estimatedPriceInr: 6,
    unitReference: '1 cup cooked',
  ),
  FoodItem(
    name: 'Oats',
    hindi: 'ओट्स',
    category: 'carb',
    proteinPer100g: 13,
    carbsPer100g: 67,
    fatPer100g: 6.5,
    caloriesPer100g: 389,
    defaultPortionGrams: 40,
    estimatedPriceInr: 7,
    unitReference: '40 g dry',
  ),
  FoodItem(
    name: 'Potato, boiled',
    hindi: 'आलू',
    category: 'carb',
    proteinPer100g: 1.9,
    carbsPer100g: 17,
    fatPer100g: 0.1,
    caloriesPer100g: 87,
    defaultPortionGrams: 150,
    estimatedPriceInr: 5,
    unitReference: '1 medium',
  ),
  FoodItem(
    name: 'Banana',
    hindi: 'केला',
    category: 'fruit',
    proteinPer100g: 1.1,
    carbsPer100g: 23,
    fatPer100g: 0.3,
    caloriesPer100g: 89,
    defaultPortionGrams: 120,
    estimatedPriceInr: 6,
    unitReference: '1 banana',
  ),
  FoodItem(
    name: 'Apple',
    hindi: 'सेब',
    category: 'fruit',
    proteinPer100g: 0.3,
    carbsPer100g: 14,
    fatPer100g: 0.2,
    caloriesPer100g: 52,
    defaultPortionGrams: 180,
    estimatedPriceInr: 15,
    unitReference: '1 apple',
  ),
  FoodItem(
    name: 'Spinach / palak',
    hindi: 'पालक',
    category: 'vegetable',
    proteinPer100g: 2.9,
    carbsPer100g: 3.6,
    fatPer100g: 0.4,
    caloriesPer100g: 23,
    defaultPortionGrams: 150,
    estimatedPriceInr: 15,
    unitReference: '150 g',
  ),
  FoodItem(
    name: 'Peas / matar',
    hindi: 'मटर',
    category: 'vegetable',
    proteinPer100g: 5.4,
    carbsPer100g: 14,
    fatPer100g: 0.4,
    caloriesPer100g: 81,
    defaultPortionGrams: 100,
    estimatedPriceInr: 20,
    unitReference: '100 g',
  ),
  FoodItem(
    name: 'Peanuts',
    hindi: 'मूंगफली',
    category: 'fat',
    proteinPer100g: 25.8,
    carbsPer100g: 16.1,
    fatPer100g: 49.2,
    caloriesPer100g: 567,
    defaultPortionGrams: 30,
    estimatedPriceInr: 8,
    unitReference: '30 g',
  ),
  FoodItem(
    name: 'Almonds',
    hindi: 'बादाम',
    category: 'fat',
    proteinPer100g: 21.2,
    carbsPer100g: 21.7,
    fatPer100g: 49.9,
    caloriesPer100g: 579,
    defaultPortionGrams: 20,
    estimatedPriceInr: 18,
    unitReference: 'about 15 almonds',
  ),
  FoodItem(
    name: 'Mustard oil',
    hindi: 'सरसों तेल',
    category: 'fat',
    proteinPer100g: 0,
    carbsPer100g: 0,
    fatPer100g: 100,
    caloriesPer100g: 884,
    defaultPortionGrams: 10,
    estimatedPriceInr: 2,
    unitReference: '2 tsp',
  ),
  FoodItem(
    name: 'Tofu',
    hindi: 'टोफू',
    category: 'protein',
    proteinPer100g: 8,
    carbsPer100g: 2,
    fatPer100g: 4.8,
    caloriesPer100g: 76,
    defaultPortionGrams: 150,
    estimatedPriceInr: 45,
    unitReference: '150 g',
  ),
  FoodItem(
    name: 'Sattu',
    hindi: 'सत्तू',
    category: 'legume',
    proteinPer100g: 20,
    carbsPer100g: 58,
    fatPer100g: 5,
    caloriesPer100g: 350,
    defaultPortionGrams: 50,
    estimatedPriceInr: 8,
    unitReference: '50 g dry',
  ),
  FoodItem(
    name: 'Mixed vegetables, cooked',
    hindi: 'सब्जियां',
    category: 'vegetable',
    proteinPer100g: 2,
    carbsPer100g: 9,
    fatPer100g: 2,
    caloriesPer100g: 60,
    defaultPortionGrams: 200,
    estimatedPriceInr: 20,
    unitReference: '1 bowl',
  ),
];

List<FoodItem> searchFood(String query, {int limit = 20}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return foodDb.take(limit).toList();
  final scored = <({int score, FoodItem item})>[];
  for (final item in foodDb) {
    final name = item.name.toLowerCase();
    final hindi = item.hindi.toLowerCase();
    var score = 0;
    if (name == q) score += 5;
    if (name.contains(q)) score += 3;
    if (hindi.contains(q)) score += 2;
    if (item.category == q) score += 1;
    if (score > 0) scored.add((score: score, item: item));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).map((x) => x.item).toList();
}

class DietPlanItem {
  final FoodItem food;
  final int grams;
  final double costInr;

  const DietPlanItem(this.food, this.grams, this.costInr);

  double get proteinGrams => food.proteinPer100g * grams / 100;
  double get calories => food.caloriesPer100g * grams / 100;
}

class BudgetPlan {
  final double targetInr;
  final List<DietPlanItem> items;

  const BudgetPlan(this.targetInr, this.items);

  double get totalCostInr => items.fold(0, (sum, item) => sum + item.costInr);
  double get totalProteinGrams =>
      items.fold(0, (sum, item) => sum + item.proteinGrams);
  bool get withinBudget => totalCostInr <= targetInr;
}

/// A conservative example, not a personalized calorie prescription.
BudgetPlan calculateBudget({double dailyTargetInr = 200}) {
  FoodItem byName(String name) => foodDb.firstWhere((x) => x.name == name);
  return BudgetPlan(dailyTargetInr, [
    DietPlanItem(byName('Egg, whole'), 150, 18),
    DietPlanItem(byName('Milk, toned'), 240, 12),
    DietPlanItem(byName('Chicken breast, cooked'), 100, 80),
    DietPlanItem(byName('Soy chunks, dry'), 30, 12),
    DietPlanItem(byName('Moong dal, cooked'), 200, 20),
    DietPlanItem(byName('Wheat roti'), 120, 8),
    DietPlanItem(byName('Rice, cooked'), 150, 6),
    DietPlanItem(byName('Mixed vegetables, cooked'), 200, 20),
    DietPlanItem(byName('Banana'), 120, 6),
  ]);
}

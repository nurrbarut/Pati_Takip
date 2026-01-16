import 'nutrition_strategies.dart';

class NutritionHelper {
  static final Map<String, NutritionStrategy> _strategies = {
    'kedi': CatNutrition(),
    'köpek': DogNutrition(),
    'hamster': RodentNutrition(),
    'ginepig': RodentNutrition(),
    'su kaplumbağası': TurtleNutrition(),
    'kuş': BirdNutrition(),
  };

  static double calculateDailyFood(
    double weight,
    String species,
    bool isSterilized,
  ) {
    final strategy = _strategies[species.toLowerCase()] ?? CatNutrition();
    return strategy.calculate(weight, isSterilized);
  }
}

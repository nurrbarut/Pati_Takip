import 'dart:math' as math;

abstract class NutritionStrategy {
  double calculate(double weight, bool isSterilized);
}

class CatNutrition implements NutritionStrategy {
  @override
  double calculate(double weight, bool isSterilized) {
    double rer = 70 * math.pow(weight, 0.75).toDouble();
    return (rer * (isSterilized ? 1.2 : 1.4)) / 3.8;
  }
}

class DogNutrition implements NutritionStrategy {
  @override
  double calculate(double weight, bool isSterilized) {
    double rer = 70 * math.pow(weight, 0.75).toDouble();
    return (rer * (isSterilized ? 1.6 : 1.8)) / 3.5;
  }
}

class RodentNutrition implements NutritionStrategy {
  @override
  double calculate(double weight, bool isSterilized) {
    return weight * 15;
  }
}

class TurtleNutrition implements NutritionStrategy {
  @override
  double calculate(double weight, bool isSterilized) {
    return (weight * 5);
  }
}

class BirdNutrition implements NutritionStrategy {
  @override
  double calculate(double weight, bool isSterilized) {
    return weight * 20;
  }
}

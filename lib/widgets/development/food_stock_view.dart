import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/pet.dart';
import '../../../services/nutrition_helper.dart';

class FoodStockView extends StatelessWidget {
  final Pet pet;
  final Map<String, dynamic>? currentFoodStock;
  final VoidCallback onUpdateStock;

  const FoodStockView({
    super.key,
    required this.pet,
    required this.currentFoodStock,
    required this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    double currentStockGrams = 0;
    double packageSizeGrams = 1;
    DateTime lastUpdate = DateTime.now();

    if (currentFoodStock != null) {
      currentStockGrams =
          (currentFoodStock!['currentStock'] as num?)?.toDouble() ?? 0.0;
      packageSizeGrams =
          (currentFoodStock!['packageSize'] as num?)?.toDouble() ?? 1.0;

      final dbDate =
          currentFoodStock!['updatedAt'] ?? currentFoodStock!['date'];
      if (dbDate != null && dbDate.toString().isNotEmpty) {
        try {
          lastUpdate = DateTime.parse(dbDate.toString());
        } catch (e) {
          lastUpdate = DateTime.now();
        }
      }
    }

    double dailyAmount = NutritionHelper.calculateDailyFood(
      pet.weight ?? 4.0,
      pet.species,
      pet.isSterilized,
    );

    double secondAmount = dailyAmount / 86400;
    int secondsPassed = DateTime.now().difference(lastUpdate).inSeconds;

    double consumedFood =
        (secondsPassed > 0 ? secondsPassed : 0) * secondAmount;

    double dynamicCurrentStock = (currentStockGrams - consumedFood).clamp(
      0.0,
      packageSizeGrams,
    );

    double oran = (dynamicCurrentStock / packageSizeGrams).clamp(0.0, 1.0);
    int daysLeft = dailyAmount > 0
        ? (dynamicCurrentStock / dailyAmount).floor()
        : 0;

    final Color accentColor = oran < 0.2
        ? Colors.redAccent
        : const Color(0xFF6366F1);
    final Color bgColor = const Color(0xFFF8FAFC);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "GÜNCEL MAMA STOĞU",
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.shade200,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.15),
                              blurRadius: 60,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CustomPaint(
                          painter: _PremiumGaugePainter(
                            progress: oran,
                            color: accentColor,
                          ),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (dynamicCurrentStock / 1000).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 43,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 41, 55, 78),
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "KİLOGRAM",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade300,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  Row(
                    children: [
                      _buildMetricTile(
                        context,
                        "Günlük Porsiyon",
                        "${dailyAmount.toInt()}g",
                        Icons.restaurant_rounded,
                        accentColor,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricTile(
                        context,
                        "Tahmini Bitiş",
                        daysLeft > 0 ? "$daysLeft Gün" : "Tükendi",
                        Icons.auto_graph_rounded,
                        daysLeft < 4 ? Colors.redAccent : Colors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            InkWell(
              onTap: onUpdateStock,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E293B), const Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E293B).withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "STOK GÜNCELLE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withOpacity(0.08), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _PremiumGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    if (progress > 0) {
      final angle = (2 * math.pi * progress) - (math.pi / 2);
      final dotOffset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotOffset, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

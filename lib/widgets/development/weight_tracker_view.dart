import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/pet.dart';
import 'package:intl/intl.dart';
import '/services/database_helper.dart';

class WeightTrackerView extends StatelessWidget {
  final Pet pet;
  final List<Map<String, dynamic>> weightHistory;
  final VoidCallback onAddWeight;
  final VoidCallback onUpdate;
  final String Function(double?) weightFormatter;

  const WeightTrackerView({
    super.key,
    required this.pet,
    required this.weightHistory,
    required this.onAddWeight,
    required this.onUpdate,
    required this.weightFormatter,
  });

  @override
  Widget build(BuildContext context) {
    double idealWeight = pet.targetWeight ?? 0.0;
    double firstWeight = 0;
    double minWeight = 0;
    double diff = 0;

    final String species = pet.species?.toLowerCase() ?? "";

    if (species == 'kedi') {
      idealWeight = 4.5;
    } else if (species == 'köpek') {
      idealWeight = 10.0;
    } else if (species == 'hamster' || species == 'ginepig') {
      idealWeight = 0.15;
    } else if (species == 'su kaplumbağası') {
      idealWeight = 0.5;
    } else if (species == 'kuş') {
      idealWeight = 0.04;
    } else {
      idealWeight = 5.0;
    }

    double currentWeight = pet.weight ?? 0.0;

    double deviationPercent = (idealWeight > 0)
        ? (currentWeight - idealWeight).abs() / idealWeight
        : 0.0;

    Color weightColor;
    IconData statusIcon;
    String statusText;

    if (deviationPercent > 0.15) {
      weightColor = Colors.redAccent;
      statusIcon = Icons.error_outline_rounded;
      statusText = currentWeight > idealWeight ? "Fazla Kilolu" : "Zayıf";
    } else if (deviationPercent > 0.05) {
      weightColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusText = "Takip Edilmeli";
    } else {
      weightColor = const Color(0xFFC6A664);
      statusIcon = Icons.check_circle_rounded;
      statusText = "İdeal Kiloda";
    }

    if (weightHistory.isNotEmpty) {
      final weights = weightHistory
          .map((e) => double.tryParse(e['weight'].toString()) ?? 0.0)
          .toList();
      firstWeight = weights.first;
      minWeight = weights.reduce((a, b) => a < b ? a : b);
      double lastWeight = weights.last;
      diff = lastWeight - firstWeight;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kilo Takibi",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showWeightInfoDialog(
                                  context,
                                  idealWeight,
                                  deviationPercent,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      (pet.weight == null || pet.weight == 0)
                                          ? "Henüz kilo kaydı yok"
                                          : "Mevcut: ${weightFormatter(pet.weight)}",
                                      style: TextStyle(
                                        color: weightColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      statusIcon,
                                      color: weightColor,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      IconButton(
                        onPressed: onAddWeight,
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.orange,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  SizedBox(height: 200, child: _buildChart()),
                  const SizedBox(height: 25),

                  if (weightHistory.length >= 2)
                    Row(
                      children: [
                        _buildStatTile(
                          "Başlangıç",
                          "${weightFormatter(firstWeight)}",
                          Icons.flag_rounded,
                          Colors.blue,
                        ),
                        const SizedBox(width: 13),
                        _buildStatTile(
                          "En Düşük",
                          "${weightFormatter(minWeight)}",
                          Icons.trending_down,
                          Colors.teal,
                        ),
                        const SizedBox(width: 13),
                        _buildStatTile(
                          "Değişim",
                          "${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg",
                          Icons.auto_graph,
                          diff <= 0 ? Colors.orange : Colors.redAccent,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildHistoryList(context),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: const Icon(Icons.history, color: Colors.orange),
        title: const Text(
          "Kilo Geçmişi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${weightHistory.length} Kayıt Mevcut"),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weightHistory.length,
            itemBuilder: (context, index) {
              final item = weightHistory[weightHistory.length - 1 - index];
              final weight = double.tryParse(item['weight'].toString()) ?? 0.0;
              DateTime dt = DateTime.parse(item['date']);
              return ListTile(
                title: Text(DateFormat('dd.MM.yyyy').format(dt)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weightFormatter(weight),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () =>
                          _confirmDelete(context, item['id'].toString()),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (weightHistory.isEmpty)
      return const Center(child: Text("Henüz veri yok"));

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,

            tooltipMargin: 15,
            getTooltipColor: (touchedSpot) => Colors.orange.withOpacity(0.9),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index < 0 || index >= weightHistory.length) return null;

                final rawDate = weightHistory[index]['date'];
                final weightValue = touchedSpot.y;

                DateTime dt = DateTime.parse(rawDate);
                String formattedDate = DateFormat('dd.MM.yyyy').format(dt);

                return LineTooltipItem(
                  "$formattedDate\n",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: weightFormatter(weightValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: Colors.orange.withOpacity(0.2),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Colors.orange,
                          ),
                    ),
                  );
                }).toList();
              },
        ),

        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: weightHistory
                .asMap()
                .entries
                .map(
                  (e) => FlSpot(
                    e.key.toDouble(),
                    double.tryParse(e.value['weight'].toString()) ?? 0.0,
                  ),
                )
                .toList(),
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.orange,
            barWidth: 6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.3),
                  Colors.orange.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightInfoDialog(
    BuildContext context,
    double ideal,
    double deviation,
  ) {
    final Color kEspresso = const Color(0xFF2D2424);
    final Color kGold = const Color(0xFFC6A664);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: kGold),
            const SizedBox(width: 10),
            const Text(
              "Analiz Detayı",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2424),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bu analiz, dostunuz için belirlenen ${ideal.toStringAsFixed(2)} kg ideal kilonun sapma oranına göre hesaplanmıştır:",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.check_circle,
              kGold,
              "İdeal:",
              "%5'ten az sapma",
            ),
            _buildInfoRow(
              Icons.warning_amber_rounded,
              Colors.orange,
              "Dikkat:",
              "%5 - %15 arası sapma",
            ),
            _buildInfoRow(
              Icons.error_outline,
              Colors.redAccent,
              "Kritik:",
              "%15'ten fazla sapma",
            ),
            const Divider(height: 30),
            Text(
              "Şu anki sapma oranı: %${(deviation * 100).toStringAsFixed(1)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kEspresso,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Anladım",
              style: TextStyle(color: kGold, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text(
          'Bu kilo kaydı kalıcı olarak silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DBHelper.instance.deleteWeight(id.toString());

              List<Map<String, dynamic>> updatedHistory = List.from(
                weightHistory,
              );
              updatedHistory.removeWhere(
                (item) => item['id'].toString() == id.toString(),
              );

              if (updatedHistory.isEmpty) {
                await DBHelper.instance.updatePetWeight(pet.id!, 0.0);
                pet.weight = 0.0;
              } else {
                final lastEntry = updatedHistory.last;
                final double newWeight =
                    double.tryParse(lastEntry['weight'].toString()) ?? 0.0;

                await DBHelper.instance.updatePetWeight(pet.id!, newWeight);
                pet.weight = newWeight;
              }

              onUpdate();
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

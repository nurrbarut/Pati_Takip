import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vaccination.dart';

class VaccinationHistoryView extends StatelessWidget {
  final String petName;
  final List<Map<String, dynamic>> vaccines;
  final VoidCallback onAddVaccine;
  final Function(String) onDelete;
  final Function(Map<String, dynamic>) onRenew;
  final Color headerColor;

  const VaccinationHistoryView({
    super.key,
    required this.petName,
    required this.vaccines,
    required this.onAddVaccine,
    required this.onDelete,
    required this.onRenew,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(now.year, now.month, now.day);

    final activeVaccines = vaccines.where((v) {
      return (v['isArchived'] as int? ?? 0) == 0;
    }).toList();

    activeVaccines.sort(
      (a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
    );

    int overdueCount = activeVaccines.where((v) {
      if (v['isPeriodic'] != 1) return false;
      DateTime planDate = DateTime.parse(v['date']);
      DateTime planZero = DateTime(planDate.year, planDate.month, planDate.day);
      return planZero.isBefore(today);
    }).length;

    int upcomingCount = activeVaccines.where((v) {
      if (v['isPeriodic'] != 1) return false;
      DateTime planDate = DateTime.parse(v['date']);
      DateTime planZero = DateTime(planDate.year, planDate.month, planDate.day);
      int diff = planZero.difference(today).inDays;
      return diff >= 0 && diff <= 7;
    }).length;

    int singleDoseCount = activeVaccines
        .where((v) => v['isPeriodic'] != 1)
        .length;

    Color getStatusColor() {
      if (overdueCount > 0) {
        return const Color(0xFF912C2C);
      } else if (upcomingCount > 0) {
        return const Color(0xFFB45309);
      } else {
        return const Color(0xFF7752FE);
      }
    }

    final Color currentStatusColor = getStatusColor();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            decoration: BoxDecoration(
              color: currentStatusColor,

              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: currentStatusColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildHealthSummary(
              context,
              overdueCount,
              upcomingCount,
              singleDoseCount,
              currentStatusColor,
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              "Aşı Takvimi",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          activeVaccines.isEmpty
              ? _buildEmptyState("Planlanmış bir aşı bulunmuyor.", Colors.grey)
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeVaccines.length,
                  itemBuilder: (context, index) {
                    final v = activeVaccines[index];
                    return _buildSwipeableVaccineItem(context, v);
                  },
                ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  DateTime _calculateNextDate(Map<String, dynamic> v) {
    DateTime baseDate = DateTime.parse(v['date']);

    if (v['isPeriodic'] == 1) {
      int months = (v['periodMonths'] as num? ?? 0).toInt();
      return DateTime(baseDate.year, baseDate.month + months, baseDate.day);
    }

    return baseDate;
  }

  Widget _buildHealthSummary(
    BuildContext context,
    int overdue,
    int upcoming,
    int single,
    Color statusColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [statusColor, statusColor.withOpacity(0.9)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overdue > 0
                ? "Dikkat! $overdue aşının süresi geçti ⚠️"
                : (upcoming > 0
                      ? "Yaklaşan aşı randevuların var 🗓️"
                      : "Her Şey Yolunda ✨"),
            style: TextStyle(
              color: overdue > 0 ? Colors.white : Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$petName Sağlık Özeti",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryCard(
                "Geciken",
                overdue.toString(),
                const Color(0xFFFF5252),
              ),

              _summaryCard(
                "Yaklaşan",
                upcoming.toString(),
                const Color(0xFFFFAB40),
              ),

              _summaryCard(
                "Tek Seferlik",
                single.toString(),
                const Color(0xFF40C4FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color indicatorColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),

            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: indicatorColor.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineItem(BuildContext context, Map<String, dynamic> v) {
    final vac = Vaccination.fromMap(v);
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    DateTime start;
    try {
      DateTime rawStart = v['lastDoneDate'] != null
          ? DateTime.parse(v['lastDoneDate'])
          : DateTime.parse(v['date']);
      start = DateTime(rawStart.year, rawStart.month, rawStart.day);
    } catch (_) {
      start = today;
    }

    DateTime end;
    try {
      DateTime rawEnd = DateTime.parse(v['date']);
      end = DateTime(rawEnd.year, rawEnd.month, rawEnd.day);
    } catch (_) {
      end = today.add(const Duration(days: 1));
    }

    final int totalDuration = end.difference(start).inDays;
    final int daysLeft = end.difference(today).inDays;
    final int daysPassed = today.difference(start).inDays;

    final bool isDoneToday =
        v['lastDoneDate'] != null && start.isAtSameMomentAs(today);
    final bool isOverdue = daysLeft < 0;
    final bool isTodayDue = daysLeft == 0;
    final bool isUpcoming = daysLeft > 0 && daysLeft <= 7;

    double calculateProgress() {
      if (!vac.isPeriodic) return 1.0;
      if (isOverdue) return 0.0;
      if (isDoneToday) return 1.0;
      if (totalDuration <= 0) return 0.0;

      double progress = (totalDuration - daysPassed) / totalDuration;
      return progress.clamp(0.0, 1.0);
    }

    final double progressValue = calculateProgress();

    final Color accentColor = isDoneToday
        ? Colors.green.shade600
        : (isOverdue || isTodayDue
              ? Colors.red.shade600
              : (isUpcoming ? Colors.orange.shade600 : Colors.indigo.shade600));

    String getSmartMessage() {
      if (isDoneToday)
        return "Bağışıklık süreci bugün başladı, $petName güvende! ✨";
      if (isOverdue)
        return "Bağışıklık süresi ${daysLeft.abs()} gün önce doldu! ⚠️";
      if (isTodayDue) return "Bağışıklık süresi bugün doluyor! ⚠️";
      if (isUpcoming) return "Koruma azalıyor, $daysLeft gün kaldı. 🗓️";

      return "$petName güvende, koruma seviyesi %${(progressValue * 100).toInt()}. ✅";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverdue ? accentColor.withOpacity(0.2) : Colors.grey.shade50,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildPremiumIcon(
                            accentColor,
                            isOverdue,
                            isUpcoming,
                            vac.isPeriodic,
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vac.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vac.isPeriodic
                                      ? "Sıradaki: ${DateFormat('dd.MM.yyyy', 'tr_TR').format(vac.date)}"
                                      : "Uygulama: ${DateFormat('dd.MM.yyyy', 'tr_TR').format(vac.lastDoneDate)}",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                Text(
                                  getSmartMessage(),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: accentColor.withOpacity(0.9),
                                  ),
                                ),

                                if (vac.isPeriodic) ...[
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Koruma Seviyesi",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "%${(progressValue * 100).toInt()}",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: accentColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: progressValue,
                                          backgroundColor: accentColor
                                              .withOpacity(0.08),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isOverdue
                                                    ? Colors.red.shade400
                                                    : accentColor,
                                              ),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 14,
                                          color: Colors.teal.shade400,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Kalıcı Bağışıklık",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.teal.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (vac.isPeriodic && (isOverdue || isTodayDue || isUpcoming))
              _buildActionArea(context, v, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumIcon(
    Color color,

    bool isOverdue,

    bool isUpcoming,

    bool isPeriodic,
  ) {
    IconData iconData = !isPeriodic
        ? Icons.shield_rounded
        : (isOverdue
              ? Icons.priority_high_rounded
              : Icons.event_available_rounded);

    return Container(
      width: 48,

      height: 48,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        shape: BoxShape.circle,
      ),

      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildActionArea(
    BuildContext context,

    Map<String, dynamic> v,

    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

      child: SizedBox(
        width: double.infinity,

        child: ElevatedButton(
          onPressed: () => _showConfirmDialog(context, v),

          style: ElevatedButton.styleFrom(
            backgroundColor: color,

            foregroundColor: Colors.white,

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            padding: const EdgeInsets.symmetric(vertical: 12),
          ),

          child: const Text(
            "AŞIYI GÜNCELLE",

            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableVaccineItem(
    BuildContext context,
    Map<String, dynamic> v,
  ) {
    return Dismissible(
      key: Key(v['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(context, v['name'] ?? "");
      },
      onDismissed: (direction) => onDelete(v['id'].toString()),

      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Sil",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
      child: _buildVaccineItem(context, v),
    );
  }

  void _showConfirmDialog(BuildContext context, Map<String, dynamic> vaccine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("Aşıyı Onayla"),
            ],
          ),
          content: Text(
            "${vaccine['name']} aşısının bugün yapıldığını onaylıyor musunuz?\n\nBu işlem mevcut kaydı arşive taşıyacak ve yeni bir takvim başlatacaktır.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("VAZGEÇ", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                onRenew(vaccine);
              },
              child: const Text("EVET, YAPILDI"),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    String vaccineName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kaydı Sil?"),
        content: Text(
          "$vaccineName aşısını ve buna ait tüm geçmiş arşiv kayıtlarını tamamen silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İPTAL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "HEPSİNİ SİL",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vaccines_outlined,
            size: 70,
            color: color.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

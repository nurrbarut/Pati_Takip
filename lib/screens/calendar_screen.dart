import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';
import '../services/nutrition_helper.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/notificationHelper.dart';

class CalendarScreen extends StatefulWidget {
  final String? petId;
  const CalendarScreen({super.key, this.petId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic> _selectedEvents = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _upcomingFilterOption = 30;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  DateTime? _nextVaccineDate;
  int _durationDays = 1;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Veteriner';
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _selectedDay = _focusedDay;
    _initAllData();
  }

  Future<void> _initAllData() async {
    await _loadAllEvents();
    final normalizeDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    setState(() {
      _selectedEvents = _events[normalizeDay] ?? [];
    });
  }

  Color _getEventColor(dynamic event) {
    final String type = event['type'] ?? 'normal';

    if (type == 'baslangic') {
      return Colors.green;
    } else if (type == 'bitis') {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  void _showAddAppointmentDialog() {
    _nextVaccineDate = null;
    _durationDays = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Yeni Randevu Planla",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Randevu Başlığı",
                    hintText: _selectedType == 'Veteriner'
                        ? "Örn: Karma Aşı Randevusu"
                        : _selectedType == 'İlaç'
                        ? "Örn: Vitamin Takviyesi"
                        : "Randevu adı girin",
                    prefixIcon: const Icon(Icons.edit, color: Colors.brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                const Text(
                  "Kategori",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Veteriner', 'Aşı', 'İlaç', 'Diğer'].map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      selectedColor: Colors.orange.shade200,
                      onSelected: (val) {
                        setModalState(() {
                          _selectedType = type;
                        });
                      },
                    );
                  }).toList(),
                ),

                if (_selectedType == 'Aşı') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Periyodik aşı takibi ve otomatik hesaplama için lütfen Aşı Modülü'nü kullanın.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.vaccines, size: 18),
                          label: const Text("Aşı Modülü'ne Git"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedType == 'İlaç') ...[
                  const SizedBox(height: 15),
                  const Text(
                    "İlaç Kullanım Detayı",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Kaç Gün Boyunca Kullanılacak?",
                      hintText: "Örn: 7",
                      prefixIcon: const Icon(Icons.repeat, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.teal.shade50.withOpacity(0.3),
                    ),
                    onChanged: (val) {
                      _durationDays = int.tryParse(val) ?? 1;
                    },
                  ),
                ],

                const SizedBox(height: 15),

                ListTile(
                  title: Text("Saat: ${_selectedTime.format(context)}"),
                  leading: const Icon(Icons.access_time, color: Colors.brown),
                  trailing: const Icon(Icons.chevron_right),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) setModalState(() => _selectedTime = time);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => _saveAppointment(),
                    child: const Text(
                      "Takvime İşle",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAppointment() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen bir başlık girin!")));
      return;
    }
    if (_selectedType == 'Aşı') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aşı işlemleri için lütfen Aşı Modülü'nü kullanın."),
        ),
      );
      return;
    }

    try {
      final selectedDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      String finalNotes = _selectedType == 'İlaç'
          ? "Süre: $_durationDays"
          : _notesController.text;

      final newApp = Appointment(
        id: const Uuid().v4(),
        petId: widget.petId ?? "genel",
        title: _titleController.text,
        date: selectedDateTime,
        type: _selectedType,
        notes: _selectedType == 'İlaç'
            ? "Süre: $_durationDays"
            : _notesController.text,
      );
      await DBHelper.instance.insertAppointment(newApp);

      _loadAllEvents();

      if (mounted) {
        Navigator.pop(context);
        _titleController.clear();
        _notesController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$_selectedType başarıyla eklendi"),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      debugPrint("Kayıt hatası: $e");
    }
  }

  void _addEventToMap(
    DateTime date,
    dynamic event,
    Map<DateTime, List<dynamic>> eventMap,
  ) {
    DateTime day = DateTime(date.year, date.month, date.day);

    if (eventMap[day] == null) {
      eventMap[day] = [event];
    } else {
      eventMap[day]!.add(event);
    }
  }

  Future<void> _loadAllEvents() async {
    setState(() => _isLoading = true);

    try {
      final appointments = await DBHelper.instance.getAppointments();
      final vaccinations = await DBHelper.instance.getAllVaccinations();

      final newEvents = <DateTime, List<dynamic>>{};
      void addEvent(DateTime date, dynamic item) {
        final key = DateTime(date.year, date.month, date.day);

        if (newEvents[key] == null) {
          newEvents[key] = [];
        }
        newEvents[key]!.add(item);
      }

      for (var app in appointments) {
        if (widget.petId == null || app.petId == widget.petId) {
          if (app.type == 'İlaç' && app.notes.startsWith("Süre: ")) {
            int days = int.tryParse(app.notes.split(": ")[1]) ?? 1;
            for (int i = 0; i < days; i++) {
              DateTime nextDay = app.date.add(Duration(days: i));
              addEvent(nextDay, app);
            }
          } else {
            addEvent(app.date, app);
          }
        }
      }

      for (var v in vaccinations) {
        if (widget.petId != null && v['petId'] != widget.petId) continue;
        if (v['isArchived'] == 1) continue;

        var pRaw = v['isPeriodic'];
        bool isPeriodic = (pRaw == 1 || pRaw == '1' || pRaw == true);
        if (v['lastDoneDate'] != null) {
          DateTime doneDate = DateTime.parse(v['lastDoneDate']);
          addEvent(doneDate, {
            ...v,
            'title': v['name'],
            'displayStatus': 'Tamamlandı',
            'type': 'baslangic',
            'isReminder': false,
          });
        }
        if (isPeriodic && v['date'] != null) {
          DateTime planDate = DateTime.parse(v['date']);
          DateTime doneDate = v['lastDoneDate'] != null
              ? DateTime.parse(v['lastDoneDate'])
              : DateTime(1900);
          if (planDate.isAfter(doneDate)) {
            addEvent(planDate, {
              ...v,
              'title': "${v['name']} (Hatırlatma)",
              'displayStatus': 'Bekleniyor',
              'type': 'bitis',
              'isReminder': true,
            });
          }
        } else if (!isPeriodic && v['date'] != null) {
          addEvent(DateTime.parse(v['date']), {
            ...v,
            'title': v['name'],
            'type': 'normal',
            'isReminder': true,
          });
        }
      }
      if (widget.petId != null) {
        final Map<String, dynamic>? petMap = await DBHelper.instance.getPetById(
          widget.petId!,
        );

        if (petMap != null && petMap['birthDate'] != null) {
          DateTime birthDate = DateTime.parse(petMap['birthDate']);
          DateTime now = DateTime.now();
          DateTime birthdayThisYear = DateTime(
            now.year,
            birthDate.month,
            birthDate.day,
          );
          addEvent(birthdayThisYear, {
            'id': 'bday_${birthdayThisYear.year}',
            'title': "Dostunuzun Doğum Günü! 🎂",
            'name': "${petMap['name']} Doğum Günü",
            'type': 'dogum_gunu',
            'notes': 'İyi ki doğdun ${petMap['name']}!',
            'date': birthdayThisYear.toIso8601String(),
            'isReminder': true,
          });
          DateTime notificationTarget = birthdayThisYear.isBefore(now)
              ? DateTime(now.year + 1, birthDate.month, birthDate.day)
              : birthdayThisYear;
          DateTime notificationTime = DateTime(
            notificationTarget.year,
            notificationTarget.month,
            notificationTarget.day,
            10,
            0,
          );
          try {
            await NotificationHelper.scheduleNotification(
              id: ("bday_${widget.petId}").hashCode,
              title: "İyi ki Doğdun! 🎂",
              body: "Bugün ${petMap['name']} doğum günü! Ona bir ödül ver. 🦴",
              scheduledDate: notificationTime,
            );
          } catch (_) {}
        }
      }
      if (widget.petId != null) {
        final foodData = await DBHelper.instance.getFoodStock(widget.petId!);
        final petData = await DBHelper.instance.getPetById(widget.petId!);

        if (foodData != null && petData != null) {
          double recordedStock =
              double.tryParse(foodData['currentStock'].toString()) ?? 0;
          double dailyUsage =
              double.tryParse(petData['dailyConsumption'].toString()) ?? 0;

          if (dailyUsage <= 0) {
            double w = double.tryParse(petData['weight'].toString()) ?? 4.0;
            String s = petData['species'] ?? 'Köpek';
            bool isSterilized = (petData['isSterilized'] == 1);
            dailyUsage = NutritionHelper.calculateDailyFood(w, s, isSterilized);
          }

          String? dateStr = foodData['updatedAt'] ?? foodData['lastUpdateDate'];
          DateTime lastUpdate = dateStr != null
              ? DateTime.parse(dateStr)
              : DateTime.now();

          if (recordedStock > 0 && dailyUsage > 0) {
            int secondsPassed = DateTime.now().difference(lastUpdate).inSeconds;
            double consumed =
                (secondsPassed > 0 ? secondsPassed : 0) * (dailyUsage / 86400);
            double currentStock = recordedStock - consumed;

            if (currentStock > 10) {
              int daysLeft = (currentStock / dailyUsage).floor();
              DateTime finishDate = DateTime.now().add(
                Duration(days: daysLeft),
              );
              addEvent(finishDate, {
                'id': 'auto_food',
                'title': 'Mama Bitiyor! 🥣',
                'name': 'Mama Stoğu',
                'type': 'Mama',
                'notes': 'Kalan: ${(currentStock / 1000).toStringAsFixed(1)}kg',
                'date': finishDate.toIso8601String(),
                'isReminder': true,
              });
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _events = newEvents;
          _isLoading = false;
          final normalizeDay = DateTime(
            _selectedDay.year,
            _selectedDay.month,
            _selectedDay.day,
          );
          _selectedEvents = _events[normalizeDay] ?? [];
        });
      }
    } catch (e) {
      debugPrint("HATA: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getUpcomingEvents() {
    List<dynamic> allUpcoming = [];
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    _events.forEach((date, events) {
      if (date.isAfter(now) || isSameDay(date, tomorrow)) {
        allUpcoming.addAll(events);
      }
    });

    allUpcoming.sort((a, b) {
      DateTime dateA;
      DateTime dateB;
      if (a is Map) {
        var dStr = a['date'];
        dateA = dStr != null
            ? DateTime.parse(dStr)
            : DateTime.now().add(const Duration(days: 3650));
      } else {
        dateA = a.date;
      }
      if (b is Map) {
        var dStr = b['date'];
        dateB = dStr != null
            ? DateTime.parse(dStr)
            : DateTime.now().add(const Duration(days: 3650));
      } else {
        dateB = b.date;
      }

      return dateA.compareTo(dateB);
    });

    return allUpcoming.take(2).toList();
  }

  Widget _buildFilterChip(String label, int value, StateSetter setModalState) {
    bool isSelected = _upcomingFilterOption == value;
    Color primaryColor = const Color(0xFF6D4C41);

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _upcomingFilterOption = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    final nextEvents = _getUpcomingEvents();

    if (nextEvents.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                "Yaklaşan Etkinlikler",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...nextEvents.map((event) {
            String title = "";
            DateTime date = DateTime.now();
            String type = "";

            if (event is Map) {
              title = event['title'] ?? event['name'] ?? "";
              date = DateTime.parse(event['date']);
              type = event['type'] ?? "";
            } else {
              title = event.title;
              date = event.date;
              type = event.type;
            }
            Color dotColor = Colors.indigo;

            if (type == 'dogum_gunu') {
              dotColor = Colors.purpleAccent;
            } else if (type == 'bitis') {
              dotColor = Colors.orange.shade700;
            } else if (type == 'baslangic') {
              dotColor = Colors.green;
            }
            int daysLeft = date.difference(DateTime.now()).inDays + 1;
            String timeText = daysLeft <= 1 ? "Yarın" : "$daysLeft gün sonra";

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showUpcomingEventsDialog() {
    final List<Map<String, dynamic>> allFutureEvents = [];
    final DateTime today = DateTime.now();
    final DateTime todayNormalized = DateTime(
      today.year,
      today.month,
      today.day,
    );

    _events.forEach((date, eventsList) {
      if (date.isAfter(todayNormalized) ||
          date.isAtSameMomentAs(todayNormalized)) {
        for (var event in eventsList) {
          Map<String, dynamic> eventData;
          if (event is Appointment) {
            eventData = {
              'title': event.title,
              'type': event.type,
              'notes': event.notes,
              'date': event.date.toIso8601String(),
            };
          } else if (event is Map) {
            eventData = Map<String, dynamic>.from(event);
          } else {
            continue;
          }

          eventData['sortDate'] = date;
          allFutureEvents.add(eventData);
        }
      }
    });
    allFutureEvents.sort((a, b) => a['sortDate'].compareTo(b['sortDate']));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String selectedFilter = 'all';
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            List<Map<String, dynamic>> filteredList = [];

            if (selectedFilter == 'all') {
              filteredList = List.from(allFutureEvents);
            } else {
              int dayLimit = int.parse(selectedFilter);

              filteredList = allFutureEvents.where((e) {
                DateTime eDate = e['sortDate'];
                int difference = eDate.difference(todayNormalized).inDays;
                return difference <= dayLimit;
              }).toList();
            }
            Widget buildFilterChip(String label, String value) {
              final bool isSelected = (selectedFilter == value);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setModalState(() {
                      selectedFilter = value;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4E342E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4E342E)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4E342E).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCF8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Yaklaşan Etkinlikler",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E342E),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        buildFilterChip("7 Gün", '7'),
                        const SizedBox(width: 10),
                        buildFilterChip("30 Gün", '30'),
                        const SizedBox(width: 10),
                        buildFilterChip("Tümü", 'all'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  Divider(color: Colors.grey.shade200),
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_list_off,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  selectedFilter == '7'
                                      ? "Önümüzdeki 7 gün boş! 🌿"
                                      : "Bu aralıkta plan yok 🐾",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final event = filteredList[index];
                              final DateTime date = event['sortDate'];

                              String dateLabel = DateFormat(
                                'd MMMM yyyy',
                                'tr_TR',
                              ).format(date);
                              if (date.year == today.year &&
                                  date.month == today.month &&
                                  date.day == today.day) {
                                dateLabel = "Bugün";
                              } else if (date
                                      .difference(todayNormalized)
                                      .inDays ==
                                  1) {
                                dateLabel = "Yarın";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index == 0 ||
                                      filteredList[index - 1]['sortDate'] !=
                                          date)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        bottom: 8,
                                        top: 10,
                                      ),
                                      child: Text(
                                        dateLabel,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  _buildEventCard(event),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4E342E);
    final Color bgColor = const Color(0xFFFDFCF8);
    final Color accentColor = const Color(0xFFFFAB40);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Takvim",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: -1.0,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'd MMMM',
                              'tr_TR',
                            ).format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: primaryColor,
                      ),
                      onPressed: _showUpcomingEventsDialog,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4E342E).withOpacity(0.04),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TableCalendar(
                locale: 'tr_TR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final normalizeDay = DateTime(day.year, day.month, day.day);
                  return _events[normalizeDay] ?? [];
                },
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: primaryColor,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: primaryColor,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  markersMaxCount: 0,
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.redAccent),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.map((event) {
                          Color c = Colors.grey;
                          if (event is Map) {
                            if (event['type'] == 'dogum_gunu')
                              c = const Color(0xFFE040FB);
                            else if (event['type'] == 'bitis')
                              c = const Color(0xFFFF6D00);
                            else if (event['type'] == 'baslangic')
                              c = const Color(0xFF00C853);
                            else
                              c = Colors.blue;
                          }
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    final normalizeDay = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    _selectedEvents = _events[normalizeDay] ?? [];
                  });
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              ),
            ),

            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Text(
                    DateFormat('d MMMM', 'tr_TR').format(_selectedDay),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    " Planları",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: const Color.fromARGB(255, 148, 129, 129),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Expanded(
              child: _selectedEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bubble_chart_outlined,
                            size: 70,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Bugün boş, keyfine bak! 🐾",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 100),
                      itemCount: _selectedEvents.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(_selectedEvents[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: primaryColor,
        elevation: 5,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: const Text(
          "Ekle",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEventList() {
    final dayKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final events = _events[dayKey] ?? [];

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 50,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              "Bugün için plan yok.",
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return Dismissible(
          key: Key(event is Appointment ? event.id : event['id'].toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteEvent(event);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: _buildEventCard(event),
        );
      },
    );
  }

  Future<void> _deleteEvent(dynamic event) async {
    try {
      if (event is Appointment) {
        await DBHelper.instance.deleteAppointment(event.id);
      } else {
        String id = event['id'].toString();
        await DBHelper.instance.deleteVaccination(id);
      }
      await _loadAllEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Başarıyla silindi"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  Widget _buildEventCard(dynamic event) {
    bool isMapData = event is! Appointment;
    String title = "";
    String type = "";
    String notes = "";
    DateTime eventDate = DateTime.now();

    if (isMapData) {
      title = event['title'] ?? event['name'] ?? 'Etkinlik';
      type = event['type'] ?? 'normal';
      notes = event['notes'] ?? "";
      if (event['date'] != null) eventDate = DateTime.parse(event['date']);
    } else {
      title = event.title;
      type = event.type;
      notes = event.notes;
      eventDate = event.date;
    }
    String displayType = type;

    if (type == 'Mama') {
      displayType = 'Stok Durumu 🥣';
    } else if (type == 'Veteriner') {
      displayType = 'Veteriner Randevusu';
    } else if (type == 'Kuaför') {
      displayType = 'Kuaför Randevusu';
    } else if (type == 'İlaç') {
      displayType = 'İlaç Takibi';
    } else if (type == 'baslangic') {
      displayType = 'Aşı Uygulandı';
    } else if (type == 'bitis') {
      displayType = 'Sıradaki Doz';
    } else if (type == 'dogum_gunu') {
      displayType = 'Doğum Günü';
    } else if (type == 'normal') {
      displayType = 'Tek Seferlik Aşı';
    }
    Color sideColor = Colors.indigo;
    IconData iconData = Icons.event;

    if (type == 'dogum_gunu') {
      sideColor = const Color(0xFFE040FB);
      iconData = Icons.cake;
    } else if (type == 'baslangic') {
      sideColor = const Color(0xFF00C853);
      iconData = Icons.check_circle_outline;
    } else if (type == 'bitis') {
      sideColor = const Color(0xFFFF6D00);
      iconData = Icons.notification_important_rounded;
    } else if (type == 'Veteriner') {
      sideColor = const Color(0xFFFFAB40);
      iconData = Icons.medical_services_outlined;
    } else if (type == 'Kuaför') {
      sideColor = const Color(0xFFAA00FF);
      iconData = Icons.content_cut;
    } else if (type == 'İlaç') {
      sideColor = const Color(0xFF00BFA5);
      iconData = Icons.medication_outlined;
    } else if (type == 'Mama') {
      sideColor = Colors.deepOrange;
      iconData = Icons.fastfood_rounded;
    }
    return GestureDetector(
      onTap: () {
        if (isMapData && (type == 'baslangic' || type == 'bitis')) {}
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4E342E).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 6, color: sideColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sideColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: sideColor, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: sideColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (notes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(eventDate),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/pet.dart';
import '../services/constants.dart';
import 'package:intl/intl.dart';
import '../widgets/development/food_stock_view.dart';
import '../widgets/development/weight_tracker_view.dart';
import '../widgets/development/vaccine_history_view.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';

class DevelopmentScreen extends StatefulWidget {
  final Pet pet;
  const DevelopmentScreen({super.key, required this.pet});

  @override
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _currentFoodStock;
  List<Map<String, dynamic>> _petWeightHistory = [];
  List<Map<String, dynamic>> _petVaccines = [];
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    _initAllData();
  }

  Future<void> _initAllData() async {
    if (!mounted) return;
    try {
      final history = await DBHelper.instance.getWeightHistory(widget.pet.id!);
      final vaccines = await DBHelper.instance.getVaccinationsByPet(
        widget.pet.id!,
      );
      final stock = await DBHelper.instance.getFoodStock(widget.pet.id!);

      if (mounted) {
        setState(() {
          _petWeightHistory = history;
          _currentFoodStock = stock;

          final Map<String, Map<String, dynamic>> uniqueMap = {};
          for (var v in vaccines) {
            uniqueMap[v['id'].toString()] = v;
          }
          _petVaccines = uniqueMap.values.toList();

          _events = {};

          DateTime toDate(String dateStr) {
            final d = DateTime.parse(dateStr);
            return DateTime(d.year, d.month, d.day);
          }

          for (var vaccine in _petVaccines) {
            final pVal = vaccine['isPeriodic'];
            final bool isPeriodic = (pVal == 1 || pVal == '1' || pVal == true);

            final String name = vaccine['name'] ?? 'Aşı';

            if (isPeriodic) {
              if (vaccine['lastDoneDate'] != null) {
                final DateTime startDate = toDate(vaccine['lastDoneDate']);
                if (_events[startDate] == null) _events[startDate] = [];

                _events[startDate]!.add({'title': name, 'type': 'baslangic'});
              }

              if (vaccine['date'] != null) {
                final DateTime endDate = toDate(vaccine['date']);
                if (_events[endDate] == null) _events[endDate] = [];

                _events[endDate]!.add({
                  'title': "$name (Hatırlatma)",
                  'type': 'bitis',
                });
              }
            } else {
              if (vaccine['date'] != null) {
                final DateTime oneTimeDate = toDate(vaccine['date']);
                if (_events[oneTimeDate] == null) _events[oneTimeDate] = [];

                _events[oneTimeDate]!.add({'title': name, 'type': 'normal'});
              }
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    }
  }

  void _showAddFoodDialog() {
    final TextEditingController amountController = TextEditingController();
    String? nameErrorText;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Mama Paketi'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Miktar (gram)',
            suffixText: 'gr',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              double? amount = double.tryParse(amountController.text);
              if (amount != null) {
                await DBHelper.instance.updateFoodStock(
                  widget.pet.id!,
                  amount,
                  amount,
                );
                await _initAllData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Stoğu Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showWeightEntryDialog() {
    final TextEditingController weightController = TextEditingController();
    bool isGramSelected = _isGramMode();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Ölçüm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [!isGramSelected, isGramSelected],
                onPressed: (index) =>
                    setDialogState(() => isGramSelected = index == 1),
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: Colors.orange,
                constraints: const BoxConstraints(minHeight: 35, minWidth: 60),
                children: const [Text("kg"), Text("gr")],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: weightController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isGramSelected ? 'Ağırlık (gram)' : 'Ağırlık (kg)',
                  suffixText: isGramSelected ? 'gr' : 'kg',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                double? val = double.tryParse(
                  weightController.text.replaceAll(',', '.'),
                );
                if (val != null) {
                  double finalWeight = isGramSelected ? val / 1000 : val;
                  await DBHelper.instance.insertWeight(
                    widget.pet.id!,
                    finalWeight,
                  );
                  await _initAllData();
                  if (mounted) {
                    setState(() => widget.pet.weight = finalWeight);
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddVaccineDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    bool isPeriodic = true;
    double periodValue = 12.0;

    final Set<String> existingVaccineNames = _petVaccines
        .where((v) => v['isArchived'] != 1)
        .map((v) => v['name'].toString().toLowerCase())
        .toSet();

    final Color kEspresso = const Color(0xFF2D2424);
    final Color kGold = const Color(0xFFC6A664);
    final List<String> allSuggestions = VaccineConstants.getVaccineList(
      widget.pet.species ?? "",
    );
    final bool hasTemplate = allSuggestions.isNotEmpty;

    final List<String> filteredSuggestions = allSuggestions
        .where((s) => !existingVaccineNames.contains(s.toLowerCase()))
        .toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        String? nameErrorText;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 15,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Aşı Kaydı Ekle",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kEspresso,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (!hasTemplate)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kGold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: kGold.withOpacity(0.2)),
                        ),
                        child: Text(
                          "Kişiselleştirilmiş Sağlık Takibi: ${widget.pet.species} türü için standart bir aşı takvimi bulunmamaktadır. Lütfen veterinerinizin önerilerini manuel giriniz.",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: kGold,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),

                    Autocomplete<String>(
                      optionsBuilder: (val) => allSuggestions.where(
                        (s) => s.toLowerCase().contains(val.text.toLowerCase()),
                      ),
                      onSelected: (s) => nameController.text = s,
                      fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                        return TextField(
                          controller: ctrl,
                          focusNode: focus,
                          onChanged: (v) {
                            nameController.text = v;
                            if (nameErrorText != null) {
                              setDialogState(() => nameErrorText = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Aşı Adı",
                            errorText: nameErrorText,
                            prefixIcon: const Icon(Icons.vaccines),
                            border: const OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text("Bu periyodik bir aşı mı?"),
                      subtitle: const Text(
                        "Düzenli aralıklarla tekrarlanacaksa işaretleyin.",
                      ),
                      value: isPeriodic,
                      activeColor: Colors.orange,

                      onChanged: (val) {
                        setDialogState(() {
                          isPeriodic = val;
                        });
                      },
                    ),

                    if (isPeriodic) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Tekrarlama Sıklığı: ${periodValue.toInt()} Ay",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: periodValue,
                        min: 1,
                        max: 24,
                        divisions: 23,
                        activeColor: Colors.orange,
                        label: "${periodValue.toInt()} Ay",

                        onChanged: (val) {
                          setDialogState(() {
                            periodValue = val;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.deepPurple,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (pickedDate != null) {
                          setDialogState(() => selectedDate = pickedDate);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.deepPurple,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Uygulama Tarihi",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd.MM.yyyy',
                                  ).format(selectedDate!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notlar",
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final String enteredName = nameController.text.trim();

                          if (enteredName.isEmpty) {
                            setDialogState(() {
                              nameErrorText = "Bu alan boş geçilemez!";
                            });
                            return;
                          }

                          bool alreadyExists = _petVaccines.any(
                            (v) =>
                                (v['isArchived'] as int? ?? 0) != 1 &&
                                v['name'].toString().toLowerCase() ==
                                    enteredName.toLowerCase(),
                          );

                          if (alreadyExists) {
                            _tabController.animateTo(0);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("'$enteredName' zaten ekli!"),
                              ),
                            );
                            return;
                          }

                          try {
                            final String fixedId =
                                "${widget.pet.id}_${enteredName.replaceAll(' ', '_').toLowerCase()}";

                            final now = DateTime.now();

                            final DateTime finalSelectedDate = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              now.hour,
                              now.minute,
                            );

                            DateTime? nextDoseDate;
                            if (isPeriodic) {
                              nextDoseDate = DateTime(
                                finalSelectedDate.year,
                                finalSelectedDate.month + periodValue.toInt(),
                                finalSelectedDate.day,
                                finalSelectedDate.hour,
                                finalSelectedDate.minute,
                              );
                            }

                            final newVaccine = {
                              'id': isPeriodic
                                  ? DateTime.now().millisecondsSinceEpoch
                                        .toString()
                                  : fixedId,
                              'petId': widget.pet.id,
                              'name': enteredName,

                              'date': isPeriodic
                                  ? nextDoseDate!.toIso8601String()
                                  : finalSelectedDate.toIso8601String(),
                              'isPeriodic': isPeriodic ? 1 : 0,
                              'periodMonths': isPeriodic
                                  ? periodValue.toInt()
                                  : 0,

                              'lastDoneDate': finalSelectedDate
                                  .toIso8601String(),

                              'isArchived': 0,
                              'isCompleted': 0,
                              'notes': notesController.text,
                            };

                            await DBHelper.instance.insertVaccination(
                              newVaccine,
                            );

                            setState(() {
                              DateTime normalize(DateTime d) =>
                                  DateTime(d.year, d.month, d.day);

                              if (isPeriodic) {
                                final startKey = normalize(selectedDate!);
                                if (_events[startKey] == null)
                                  _events[startKey] = [];
                                _events[startKey]!.add({
                                  'title': enteredName,
                                  'type': 'baslangic',
                                });

                                if (nextDoseDate != null) {
                                  final endKey = normalize(nextDoseDate);
                                  if (_events[endKey] == null)
                                    _events[endKey] = [];
                                  _events[endKey]!.add({
                                    'title': "$enteredName (Hatırlatma)",
                                    'type': 'bitis',
                                  });
                                }
                              } else {
                                final dateKey = normalize(selectedDate!);
                                if (_events[dateKey] == null)
                                  _events[dateKey] = [];
                                _events[dateKey]!.add({
                                  'title': enteredName,
                                  'type': 'normal',
                                });
                              }
                            });

                            _initAllData();

                            _tabController.animateTo(0);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint("Kayıt hatası: $e");
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kEspresso,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Kaydet",
                          style: GoogleFonts.outfit(
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
            );
          },
        );
      },
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  List<Widget> _buildTabs() {
    return const [
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vaccines, size: 18),
            SizedBox(width: 8),
            Text("Sağlık"),
          ],
        ),
      ),
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight, size: 18),
            SizedBox(width: 8),
            Text("Kilo"),
          ],
        ),
      ),
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 18),
            SizedBox(width: 8),
            Text("Mama"),
          ],
        ),
      ),
    ];
  }

  Future<void> _deleteVaccine(String id) async {
    await DBHelper.instance.deleteVaccination(id);

    _initAllData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aşı kaydı kalıcı olarak silindi."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleRenewVaccine(Map<String, dynamic> oldVaccine) async {
    final db = await DBHelper.instance.database;
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    await db.update(
      'vaccinations',
      {'isArchived': 1, 'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [oldVaccine['id']],
    );

    int period = (oldVaccine['periodMonths'] as num? ?? 1).toInt();

    DateTime nextDate = DateTime(today.year, today.month + period, today.day);

    final newVaccine = {
      'id': "vax_${now.microsecondsSinceEpoch}",
      'petId': oldVaccine['petId'],
      'name': oldVaccine['name'],
      'date': nextDate.toIso8601String(),

      'lastDoneDate': today.toIso8601String(),
      'isPeriodic': 1,
      'periodMonths': period,
      'isArchived': 0,
      'isCompleted': 0,
      'notes': oldVaccine['notes'],
    };

    await db.insert('vaccinations', newVaccine);
    await _initAllData();
  }

  String formatWeight(double? weight) {
    if (weight == null || weight == 0) return "0 kg";
    if (_isGramMode()) {
      return "${(weight * 1000).toStringAsFixed(0)} gr";
    } else {
      return "${weight.toStringAsFixed(1)} kg";
    }
  }

  bool _isGramMode() {
    List<String> smallPets = ['kuş', 'hamster', 'ginepig', 'su kaplumbağası'];
    String species = widget.pet.species.toLowerCase();
    if (smallPets.contains(species)) return true;
    if (widget.pet.weight != null && widget.pet.weight! < 2.0) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final bool hasOverdue = _petVaccines.any(
      (v) => v['isCompleted'] == 0 && DateTime.parse(v['date']).isBefore(today),
    );

    final bool hasUpcoming = _petVaccines.any((v) {
      final diff = DateTime.parse(v['date']).difference(today).inDays;
      return v['isCompleted'] == 0 && diff >= 0 && diff <= 7;
    });

    final Color healthColor = hasOverdue
        ? const Color(0xFF912C2C)
        : (hasUpcoming ? const Color(0xFFB45309) : const Color(0xFF7752FE));

    final Color activeColor = _selectedTabIndex == 0
        ? healthColor
        : (_selectedTabIndex == 1
              ? const Color.fromARGB(255, 255, 101, 30)
              : const Color.fromARGB(255, 14, 186, 225));

    final Map<String, Map<String, dynamic>> uniqueVaccinesMap = {};
    for (var v in _petVaccines) {
      uniqueVaccinesMap[v['id'].toString()] = v;
    }
    final List<Map<String, dynamic>> cleanedVaccines = uniqueVaccinesMap.values
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: activeColor,
          elevation: 0,
          toolbarHeight: 80,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                widget.pet.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const Text(
                "Gelişim Paneli",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          leading: _buildLeading(context),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                labelColor: activeColor,
                unselectedLabelColor: Colors.white,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: _buildTabs(),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  VaccinationHistoryView(
                    petName: widget.pet.name,
                    vaccines: cleanedVaccines,
                    onAddVaccine: _showAddVaccineDialog,
                    onDelete: _deleteVaccine,
                    onRenew: _handleRenewVaccine,

                    headerColor: healthColor,
                  ),
                  WeightTrackerView(
                    pet: widget.pet,
                    weightHistory: _petWeightHistory,
                    onAddWeight: _showWeightEntryDialog,
                    onUpdate: _initAllData,
                    weightFormatter: formatWeight,
                  ),
                  FoodStockView(
                    pet: widget.pet,
                    currentFoodStock: _currentFoodStock,
                    onUpdateStock: _showAddFoodDialog,
                  ),
                ],
              ),
        floatingActionButton: _selectedTabIndex == 0
            ? FloatingActionButton.extended(
                onPressed: _showAddVaccineDialog,
                backgroundColor: healthColor,
                label: const Text(
                  "Aşı Ekle",
                  style: TextStyle(color: Colors.white),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}

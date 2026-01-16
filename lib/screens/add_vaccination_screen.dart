import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vaccination.dart';
import '../services/database_helper.dart';
import '../services/constants.dart';

class AddVaccinationScreen extends StatefulWidget {
  final String petId;
  final String species;

  const AddVaccinationScreen({
    super.key,
    required this.petId,
    required this.species,
  });

  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isPeriodic = false;
  int _periodMonths = 3;

  String? _selectedDropdownValue;
  bool _isManualEntry = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final List<String> items = [
      ...VaccineConstants.getVaccineList(widget.species),
      "Diğer...",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Aşı Kaydı Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Aşı Seçimi",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedDropdownValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vaccines),
              ),
              hint: const Text("Yapılan aşıyı seçin"),
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDropdownValue = val;
                  if (val == "Diğer...") {
                    _isManualEntry = true;
                    _nameController.clear();
                  } else {
                    _isManualEntry = false;
                    _nameController.text = val ?? "";
                  }
                });
              },
            ),

            if (_isManualEntry) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Aşı Adı',
                  hintText: 'Örn: Karma Aşı',
                  border: OutlineInputBorder(),
                ),

                inputFormatters: const [],
                validator: (value) => value == null || value.isEmpty
                    ? 'Lütfen aşı adını yazın'
                    : null,
              ),
            ],

            const SizedBox(height: 25),
            const Divider(),

            ListTile(
              title: const Text('Uygulama Tarihi'),
              subtitle: Text(
                DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _presentDatePicker,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            const SizedBox(height: 15),

            SwitchListTile(
              title: const Text('Bu aşı tekrarlanacak mı?'),
              subtitle: const Text(
                'Periyodik aşılar takvimde otomatik gösterilir.',
              ),
              value: _isPeriodic,
              activeColor: Colors.teal,
              onChanged: (val) => setState(() => _isPeriodic = val),
            ),

            if (_isPeriodic) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Her $_periodMonths Ayda Bir',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Slider(
                      value: _periodMonths.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 23,
                      activeColor: Colors.teal,
                      onChanged: (val) =>
                          setState(() => _periodMonths = val.toInt()),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        await _saveVaccination();
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        debugPrint("Hata: $e");
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                disabledBackgroundColor: Colors.teal.withOpacity(0.5),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'KAYDI TAMAMLA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _presentDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveVaccination() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime doneDate = _selectedDate;
    DateTime nextDate = doneDate;
    if (_isPeriodic) {
      nextDate = DateTime(
        doneDate.year,
        doneDate.month + _periodMonths,
        doneDate.day,
      );
    }

    String uniqueId =
        "${widget.petId}_${_nameController.text.trim()}_${doneDate.millisecondsSinceEpoch}";

    final newVaccination = Vaccination(
      id: uniqueId,
      petId: widget.petId,
      name: _nameController.text.trim(),
      date: nextDate,
      lastDoneDate: doneDate,
      isPeriodic: _isPeriodic,
      periodMonths: _isPeriodic ? _periodMonths : 0,
    );

    await DBHelper.instance.insertVaccination(newVaccination.toMap());
  }
}

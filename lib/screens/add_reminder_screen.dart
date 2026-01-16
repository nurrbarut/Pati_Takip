import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';

class AddReminderScreen extends StatefulWidget {
  final Pet pet;

  const AddReminderScreen({super.key, required this.pet});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  ReminderType _selectedType = ReminderType.appointment;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  String _getReminderTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.appointment:
        return 'Veteriner Randevusu';
      case ReminderType.medication:
        return 'İlaç/Vitamin Saati';
      case ReminderType.grooming:
        return 'Tüy/Tırnak Bakımı';
      case ReminderType.general:
        return 'Genel Hatırlatma';
    }
  }

  void _saveReminder() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newReminder = Reminder(
        petId: widget.pet.id,
        title: _titleController.text,
        date: _selectedDate!,
        type: _selectedType,
        isCompleted: false,
      );

      await DBHelper.instance.insertReminder(newReminder.toMap());

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen tüm zorunlu alanları (Başlık ve Tarih) doldurun.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pet.name} İçin Randevu/Hatırlatma Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<ReminderType>(
                decoration: const InputDecoration(
                  labelText: 'Hatırlatma Türü',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                items: ReminderType.values.map((ReminderType type) {
                  return DropdownMenuItem<ReminderType>(
                    value: type,
                    child: Text(_getReminderTypeName(type)),
                  );
                }).toList(),
                onChanged: (ReminderType? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık / Kısa Açıklama',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir başlık girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: 'Tarih',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Lütfen bir tarih seçin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Hatırlatmayı Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

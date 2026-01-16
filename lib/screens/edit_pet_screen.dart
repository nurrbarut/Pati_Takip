import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/pet.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/constants.dart';

class EditPetScreen extends StatefulWidget {
  final Pet pet;

  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final Color kEspresso = const Color(0xFF2D2424);
  final Color kGold = const Color(0xFFC6A664);
  final Color kCream = const Color(0xFFFAF9F6);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isPickerActive = false;
  late TextEditingController _targetWeightController;
  late TextEditingController _weightController;
  late TextEditingController _nameController;
  late String _selectedGender;
  late bool _isSterilized;
  late DateTime _selectedBirthDate;
  String? _photoPath;
  bool _isGramSelected = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    double currentWeight = widget.pet.weight ?? 0.0;
    _isGramSelected = currentWeight > 0 && currentWeight < 1.0;
    double displayWeight = _isGramSelected
        ? currentWeight * 1000
        : currentWeight;
    _weightController = TextEditingController(
      text: displayWeight == 0
          ? ""
          : displayWeight.toStringAsFixed(_isGramSelected ? 0 : 1),
    );
    _targetWeightController = TextEditingController(
      text: (widget.pet.targetWeight == null || widget.pet.targetWeight == 0)
          ? ""
          : widget.pet.targetWeight.toString(),
    );
    _selectedBirthDate = widget.pet.birthDate;
    _selectedGender = widget.pet.gender;
    _isSterilized = widget.pet.isSterilized;
    _photoPath = widget.pet.photoPath;
  }

  Future<void> _pickImage() async {
    if (_isPickerActive) return;
    try {
      setState(() => _isPickerActive = true);
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'pet_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localImage = File('${directory.path}/$fileName');
        final File savedImage = await File(image.path).copy(localImage.path);
        setState(() => _photoPath = savedImage.path);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galeri hatası: ${e.message}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kGold,
              onPrimary: Colors.white,
              onSurface: kEspresso,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  void _updatePet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);
    try {
      double enteredWeight =
          double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
      double finalWeight = _isGramSelected
          ? enteredWeight / 1000
          : enteredWeight;

      Map<String, dynamic> petData = {
        'id': widget.pet.id,
        'name': _nameController.text.trim(),
        'species': widget.pet.species,
        'birthDate': _selectedBirthDate.toIso8601String(),
        'gender': _selectedGender,
        'isSterilized': _isSterilized ? 1 : 0,
        'photoPath': _photoPath,
        'weight': finalWeight,
        'targetWeight':
            double.tryParse(
              _targetWeightController.text.replaceAll(',', '.'),
            ) ??
            0.0,
        'foodStockKg': widget.pet.foodStockKg,
      };

      await DBHelper.instance.updatePet(petData);
      if (finalWeight > 0)
        await DBHelper.instance.insertWeight(widget.pet.id, finalWeight);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kEspresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profili Düzenle',
          style: GoogleFonts.outfit(
            color: kEspresso,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 40),
            _buildSectionTitle("TEMEL BİLGİLER"),
            const SizedBox(height: 15),
            _buildTextField(_nameController, "İsim", Icons.edit_outlined),
            const SizedBox(height: 15),
            _buildGenderSelector(),
            const SizedBox(height: 30),
            _buildSectionTitle("DURUM VE ÖLÇÜMLER"),
            const SizedBox(height: 15),
            _buildWeightSection(),
            const SizedBox(height: 12),

            _buildTargetWeightSection(),

            const SizedBox(height: 20),
            const SizedBox(height: 15),
            _buildSterilizedSwitch(),
            const SizedBox(height: 15),
            _buildDatePickerField(),
            const SizedBox(height: 50),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        letterSpacing: 3,
        fontWeight: FontWeight.bold,
        color: kGold,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(45),
                boxShadow: [
                  BoxShadow(
                    color: kEspresso.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: DecorationImage(
                  image: (_photoPath != null && File(_photoPath!).existsSync())
                      ? FileImage(File(_photoPath!))
                      : AssetImage(
                              SpeciesConstants.getDefaultAsset(
                                widget.pet.species,
                              ),
                            )
                            as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.outfit(color: kEspresso),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kGold, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        validator: (val) => val!.isEmpty ? 'Boş bırakılamaz' : null,
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _pickBirthDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: kGold, size: 20),
            const SizedBox(width: 15),
            Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedBirthDate),
              style: GoogleFonts.outfit(color: kEspresso),
            ),
            const Spacer(),
            Icon(
              Icons.edit_calendar_outlined,
              color: kGold.withOpacity(0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ağırlık",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: kEspresso,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: kCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _unitBtn("kg", !_isGramSelected),
                    _unitBtn("gr", _isGramSelected),
                  ],
                ),
              ),
            ],
          ),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kEspresso,
            ),
            decoration: InputDecoration(
              hintText: "0.0",
              border: InputBorder.none,
              suffixText: _isGramSelected ? "gr" : "kg",
              suffixStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetWeightSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes_rounded, color: kGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "İdeal Hedef",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: kEspresso,
                    ),
                  ),
                ],
              ),
              Text(
                _isGramSelected ? "Gram (gr)" : "Kilogram (kg)",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          TextField(
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kEspresso,
            ),
            decoration: InputDecoration(
              hintText: "0.0",
              border: InputBorder.none,
              suffixText: _isGramSelected ? "gr" : "kg",
              suffixStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
            ),
          ),
          Text(
            "Dostunuzun olması gereken sağlıklı kiloyu buradan güncelleyebilirsiniz.",
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitBtn(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isGramSelected = label == "gr";
          double? val = double.tryParse(
            _weightController.text.replaceAll(',', '.'),
          );
          if (val != null) {
            _weightController.text = _isGramSelected
                ? (val * 1000).toStringAsFixed(0)
                : (val / 1000).toStringAsFixed(2);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _genderBtn("Erkek", Icons.male),
        const SizedBox(width: 15),
        _genderBtn("Dişi", Icons.female),
      ],
    );
  }

  Widget _genderBtn(String gender, IconData icon) {
    bool selected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kEspresso : Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                gender,
                style: GoogleFonts.outfit(
                  color: selected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSterilizedSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        title: Text(
          "Kısırlaştırılmış mı?",
          style: GoogleFonts.outfit(
            color: kEspresso,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: _isSterilized,
        activeColor: kGold,
        onChanged: (val) => setState(() => _isSterilized = val),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _updatePet,
        style: ElevatedButton.styleFrom(
          backgroundColor: kEspresso,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isUpdating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "DEĞİŞİKLİKLERİ KAYDET",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../models/pet.dart';
import '../services/database_helper.dart';
import '../services/constants.dart';
import 'package:flutter/services.dart';

class PetFormScreen extends StatefulWidget {
  final String initialSpecies;
  const PetFormScreen({super.key, required this.initialSpecies});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final Color kEspresso = const Color(0xFF2D2424);
  final Color kGold = const Color(0xFFC6A664);
  final Color kCream = const Color(0xFFFAF9F6);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthDateController = TextEditingController();
  late TextEditingController _targetWeightController;

  bool _isLoading = false;
  bool _isGramSelected = false;
  bool _isSterilized = false;
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _imagePath;

  @override
  void initState() {
    super.initState();

    _targetWeightController = TextEditingController();
  }

  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  bool _isPickerActive = false;

  Future<void> _pickImage() async {
    if (_isPickerActive) return;

    try {
      setState(() => _isPickerActive = true);

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Galeri Erişim Hatası: ${e.code}");

      if (mounted) {
        String errorMessage = "Galeriye erişilemedi.";

        if (e.code == 'photo_access_denied') {
          errorMessage =
              "Galeri izni reddedildi. Lütfen ayarlardan izin verin.";
        } else if (e.code == 'already_active') {
          errorMessage = "Fotoğraf seçici zaten açık.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Beklenmedik Hata: $e");
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _savePet() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedGender == null) {
      _showMinimalSnackBar('Lütfen tüm alanları doldurun.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      double weightValue =
          double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;

      double targetWeightValue =
          double.tryParse(_targetWeightController.text.replaceAll(',', '.')) ??
          0.0;

      List<String> smallPets = ['kuş', 'hamster', 'ginepig', 'su kaplumbağası'];

      if (smallPets.contains(widget.initialSpecies.toLowerCase()) &&
          weightValue > 10) {
        weightValue = weightValue / 1000;
      }

      if (smallPets.contains(widget.initialSpecies.toLowerCase()) &&
          targetWeightValue > 10) {
        targetWeightValue = targetWeightValue / 1000;
      }

      final newPet = Pet(
        name: _nameController.text.trim(),
        species: widget.initialSpecies,
        birthDate: _selectedDate!,
        gender: _selectedGender!,
        isSterilized: _isSterilized,
        photoPath: _imagePath,
        weight: weightValue,
        targetWeight: targetWeightValue,
        foodStockKg: 0.0,
      );

      debugPrint("Veritabanına kaydediliyor...");

      await DBHelper.instance.insertPet(newPet.toMap());

      if (weightValue > 0) {
        await DBHelper.instance.insertWeight(newPet.id, weightValue);
        debugPrint("Kilo kaydı başarılı.");
      }

      if (!mounted) return;

      _showMinimalSnackBar('Dostunuz başarıyla kaydedildi!');

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      debugPrint("KRİTİK KAYIT HATASI: $e");
      if (mounted) {
        _showMinimalSnackBar(
          'Kayıt sırasında bir sorun oluştu.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMinimalSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFC6A664),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
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
          'Yeni Dost Ekle',
          style: GoogleFonts.outfit(
            color: kEspresso,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 30),
              _buildSectionTitle("TEMEL BİLGİLER"),
              const SizedBox(height: 15),
              _buildTextField(_nameController, "İsim", Icons.edit_outlined),
              const SizedBox(height: 15),
              _buildGenderSelector(),
              const SizedBox(height: 30),

              const SizedBox(height: 20),

              _buildSectionTitle("İDEAL HEDEF"),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kEspresso.withOpacity(0.03),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.outfit(
                    color: kEspresso,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'İdeal Kilo (Hedef)',
                    labelStyle: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.track_changes_rounded, color: kGold),
                    suffixText: "kg",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Dostunuzun olması gereken ideal kiloyu buraya girin.",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 15),
              _buildWeightField(),
              const SizedBox(height: 15),
              _buildSterilizedSwitch(),
              const SizedBox(height: 15),
              _buildTextField(
                _birthDateController,
                "Doğum Tarihi",
                Icons.calendar_today_outlined,
                isReadOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        letterSpacing: 2,
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
                  image: _imagePath != null
                      ? FileImage(File(_imagePath!))
                      : AssetImage(
                              SpeciesConstants.getDefaultAsset(
                                widget.initialSpecies,
                              ),
                            )
                            as ImageProvider,
                  fit: BoxFit.cover,
                  colorFilter: _imagePath == null
                      ? ColorFilter.mode(
                          Colors.black.withOpacity(0.1),
                          BlendMode.darken,
                        )
                      : null,
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
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        onTap: onTap,
        style: GoogleFonts.outfit(color: kEspresso),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.grey),
          prefixIcon: Icon(icon, color: kGold, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Lütfen doldurun' : null,
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _genderButton('Erkek', Icons.male),
        const SizedBox(width: 15),
        _genderButton('Dişi', Icons.female),
      ],
    );
  }

  Widget _genderButton(String gender, IconData icon) {
    bool isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kEspresso : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                gender,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightField() {
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
            keyboardType: TextInputType.number,
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

  Widget _unitBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _isGramSelected = label == "gr"),
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

  Widget _buildSterilizedSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        title: Text(
          "Kısırlaştırıldı mı?",
          style: GoogleFonts.outfit(
            color: kEspresso,
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
        onPressed: _isLoading ? null : _savePet,
        style: ElevatedButton.styleFrom(
          backgroundColor: kEspresso,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Dostumu Kaydet",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

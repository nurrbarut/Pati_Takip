import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet.dart';
import '../models/vaccination.dart';
import '../models/reminder.dart';
import '../services/constants.dart';
import '../services/database_helper.dart';
import 'calendar_screen.dart';
import 'development_screen.dart';
import 'edit_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Pet? _currentPet;
  List<Vaccination> _vaccinations = [];
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  bool _wasEdited = false;

  final Color kEspresso = const Color(0xFF2D2424);
  final Color kGold = const Color(0xFFC6A664);
  final Color kCream = const Color(0xFFFAF9F6);

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    final rawVaccinations = await DBHelper.instance.getVaccinationsByPet(
      widget.pet.id,
    );
    final rawReminders = await DBHelper.instance.getRemindersByPet(
      widget.pet.id,
    );
    setState(() {
      _vaccinations = rawVaccinations
          .map((map) => Vaccination.fromMap(map))
          .toList();
      _reminders = rawReminders.map((map) => Reminder.fromMap(map)).toList();
      _isLoading = false;
    });
  }

  void _navigateToEditPet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPetScreen(pet: _currentPet!)),
    );

    if (result == true) {
      _wasEdited = true;
      final updatedData = await DBHelper.instance.getPetById(_currentPet!.id);
      if (updatedData != null) {
        setState(() {
          _currentPet = Pet.fromMap(updatedData);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kGold))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 400.0,
                  pinned: true,
                  elevation: 0,
                  stretch: true,
                  backgroundColor: kEspresso,

                  leading: _buildBackBtn(),

                  actions: [_buildMenuBtn()],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [_buildHeroImage(), _buildGradientOverlay()],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 100),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditorialHeader(),
                        const SizedBox(height: 25),

                        _buildSectionTitle("TEMEL BİLGİLER"),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          'Yaş',
                          _currentPet?.ageString ?? widget.pet.ageString,
                          Icons.cake_outlined,
                          Colors.brown.shade300,
                        ),
                        _buildInfoRow(
                          'Cinsiyet',
                          _currentPet?.gender ?? widget.pet.gender,
                          widget.pet.gender == 'Erkek'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          widget.pet.gender == 'Erkek'
                              ? Colors.blue.shade300
                              : Colors.pink.shade300,
                        ),
                        _buildInfoRow(
                          'Kısırlaştırılma',
                          (_currentPet?.isSterilized ?? widget.pet.isSterilized)
                              ? 'Evet'
                              : 'Hayır',
                          Icons.favorite_rounded,
                          Colors.red.shade300,
                        ),

                        const SizedBox(height: 40),
                        _buildDevelopmentButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBackBtn() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context, _wasEdited),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBtn() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditPet();
                } else if (value == 'calendar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarScreen(
                        petId: _currentPet?.id ?? widget.pet.id,
                      ),
                    ),
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              itemBuilder: (context) => [
                _buildPopupItem(
                  'calendar',
                  Icons.calendar_today_rounded,
                  'Pati Takvimi',
                  kGold,
                ),
                _buildPopupItem(
                  'edit',
                  Icons.edit_note_rounded,
                  'Bilgileri Düzenle',
                  kEspresso,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text,
    Color iconColor,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Hero(
      tag: 'pet_img_${_currentPet?.id ?? widget.pet.id}',
      child: Image(
        image:
            (_currentPet?.photoPath != null &&
                File(_currentPet!.photoPath!).existsSync())
            ? FileImage(File(_currentPet!.photoPath!))
            : AssetImage(
                    SpeciesConstants.getDefaultAsset(
                      _currentPet?.species ?? widget.pet.species,
                    ),
                  )
                  as ImageProvider,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.2), Colors.transparent, kCream],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentPet?.species.toUpperCase() ??
              widget.pet.species.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
            color: kGold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentPet?.name ?? widget.pet.name,
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: kEspresso,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kEspresso.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kEspresso.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kEspresso,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildDevelopmentButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DevelopmentScreen(pet: _currentPet ?? widget.pet),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kEspresso,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kEspresso.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              "Gelişim ve Kilo Takibi",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

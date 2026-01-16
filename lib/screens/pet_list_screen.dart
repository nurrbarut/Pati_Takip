import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet.dart';
import '../services/database_helper.dart';
import '../services/constants.dart';
import 'pet_detail_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;

  final Color kEspresso = const Color(0xFF2D2424);
  final Color kGold = const Color(0xFFC6A664);
  final Color kCream = const Color(0xFFFAF9F6);

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  void _fetchPets() async {
    setState(() => _isLoading = true);

    final petsMapList = await DBHelper.instance.getPetsMapList();
    final petsList = petsMapList.map((petMap) => Pet.fromMap(petMap)).toList();

    setState(() {
      _pets = petsList;
      _isLoading = false;
    });
  }

  void _handleDelete(Pet pet) async {
    HapticFeedback.mediumImpact();

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Emin misiniz?",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: kEspresso,
          ),
        ),
        content: Text(
          "${pet.name} dostumuzu silmek istediğinize emin misiniz?",
          style: GoogleFonts.outfit(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Vazgeç",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Sil", style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deletePet(pet.id);
      _fetchPets();
    } else {
      _fetchPets();
    }
  }

  Future<bool?> _showDeleteConfirmation(Pet pet) async {
    HapticFeedback.mediumImpact();

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Emin misiniz?",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: kEspresso,
          ),
        ),
        content: Text(
          "${pet.name} dostumuzu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
          style: GoogleFonts.outfit(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Vazgeç",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await DBHelper.instance.deletePet(pet.id);
              if (mounted) Navigator.pop(context, true);
              _fetchPets();
            },
            child: Text("Sil", style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AİLENİZ",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                        color: kGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pati Dostlarım",
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: kEspresso,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _pets.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final pet = _pets[index];

                        return Dismissible(
                          key: Key('dismiss_${pet.id}'),

                          direction: DismissDirection.endToStart,

                          background: _buildDeleteBackground(),

                          confirmDismiss: (direction) async {
                            bool? confirm = await _showDeleteConfirmation(pet);
                            return confirm;
                          },

                          child: _buildZenPetCard(pet),
                        );
                      }, childCount: _pets.length),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFFEEBEE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFFE57373),
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_outlined,
                size: 80,
                color: kGold.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              "Henüz Bir Dost Yok",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kEspresso,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              "Ailenizde henüz bir üye yok! Yeni bir dost eklemek için aşağıdaki '+' butonuna dokunabilirsiniz.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            Icon(
              Icons.keyboard_double_arrow_down_rounded,
              color: kGold.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZenPetCard(Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: kEspresso.withOpacity(0.03),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),

        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PetDetailScreen(pet: pet)),
          );

          await Future.delayed(const Duration(milliseconds: 100));

          _fetchPets();

          print("Liste tazelendi! 🐾");
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: 'pet_img_${pet.id}',
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kCream, width: 2),
                    image: DecorationImage(
                      image:
                          (pet.photoPath != null &&
                              File(pet.photoPath!).existsSync())
                          ? FileImage(File(pet.photoPath!)) as ImageProvider
                          : AssetImage(
                              SpeciesConstants.getDefaultAsset(pet.species),
                            ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kEspresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${pet.species} • ${pet.ageString}",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    pet.gender == 'Erkek'
                        ? Icons.male_rounded
                        : Icons.female_rounded,
                    size: 18,
                    color: pet.gender == 'Erkek'
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.pink.withOpacity(0.3),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: kGold.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/constants.dart';
import 'pet_form_screen.dart';

class SelectSpeciesScreen extends StatelessWidget {
  const SelectSpeciesScreen({super.key});

  final Color kEspresso = const Color(0xFF2D2424);
  final Color kGold = const Color(0xFFC6A664);
  final Color kCream = const Color(0xFFFAF9F6);

  void _openPetForm(BuildContext context, String speciesName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetFormScreen(initialSpecies: speciesName),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context, true);
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
          icon: Icon(Icons.arrow_back_ios_new, color: kEspresso, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "YENİ BİR BAŞLANGIÇ",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                      color: kGold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Aileye Kim Katılıyor?",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: kEspresso,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 25,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final species = SpeciesConstants.speciesList[index];
                return _buildBoutiqueSpeciesCard(context, species);
              }, childCount: SpeciesConstants.speciesList.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBoutiqueSpeciesCard(
    BuildContext context,
    Map<String, dynamic> species,
  ) {
    final speciesName = species['name']!;
    final assetPath = species['defaultAssetPath']!;

    return GestureDetector(
      onTap: () => _openPetForm(context, speciesName),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: kEspresso.withOpacity(0.04),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: DecorationImage(
                  image: AssetImage(assetPath),
                  fit: BoxFit.cover,
                ),

                boxShadow: [
                  BoxShadow(
                    color: kGold.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              speciesName,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kEspresso,
              ),
            ),
            const SizedBox(height: 4),

            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

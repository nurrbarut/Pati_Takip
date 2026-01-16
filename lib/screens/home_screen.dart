import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pet_list_screen.dart';
import 'map_screen.dart';
import 'select_species_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Key _listKey = UniqueKey();

  final Color kDark = const Color(0xFF2D2424);
  final Color kWarm = const Color(0xFFE0A370);
  final Color kBg = const Color(0xFFFAF7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PetListScreen(key: _listKey),
          const MapScreen(),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 30),
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: kDark.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildChicNavItem(Icons.grid_view_rounded, 0),
            _buildCenterAddButton(),
            _buildChicNavItem(Icons.map_rounded, 1),
          ],
        ),
      ),
    );
  }

  Widget _buildChicNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? kWarm.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? kWarm : Colors.grey.shade300,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return GestureDetector(
      onTap: () => _navigateToAddPet(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kDark.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  void _navigateToAddPet(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectSpeciesScreen()),
    );
    if (result == true)
      setState(() {
        _listKey = UniqueKey();
        _selectedIndex = 0;
      });
  }
}

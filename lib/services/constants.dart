import 'package:flutter/material.dart';

class SpeciesConstants {
  static const List<Map<String, dynamic>> speciesList = [
    {
      'name': 'Kedi',
      'icon': Icons.pets_sharp,
      'defaultAssetPath': 'assets/images/kedi.jpg',
    },
    {
      'name': 'Köpek',
      'icon': Icons.pets,
      'defaultAssetPath': 'assets/images/kopek.jpg',
    },
    {
      'name': 'Hamster',
      'icon': Icons.mouse,
      'defaultAssetPath': 'assets/images/hamster.jpg',
    },
    {
      'name': 'Ginepig',
      'icon': Icons.pets_sharp,
      'defaultAssetPath': 'assets/images/ginepig.jpg',
    },
    {
      'name': 'Su Kaplumbağası',
      'icon': Icons.cruelty_free,
      'defaultAssetPath': 'assets/images/kaplumbaga.jpg',
    },
    {
      'name': 'Kuş',
      'icon': Icons.flutter_dash,
      'defaultAssetPath': 'assets/images/kus.jpg',
    },
  ];

  static String getDefaultAsset(String speciesName) {
    final species = speciesList.firstWhere(
      (s) => s['name'] == speciesName,
      orElse: () => speciesList[0],
    );
    return species['defaultAssetPath'];
  }
}

class VaccineConstants {
  static const List<String> catVaccines = [
    'Karma Aşı (FVRCP)',
    'İç Parazit',
    'Dış Parazit',
    'Kuduz Aşısı',
    'Lösemi Aşısı (FeLV)',
    'Bronşit Aşısı (Bordetella)',
  ];

  static const List<String> dogVaccines = [
    'Karma Aşı (DHPP)',
    'İç Parazit',
    'Dış Parazit',
    'Kuduz Aşısı',
    'Bronşit Aşısı (Kennel Cough)',
    'Lyme Aşısı',
    'Korona Aşısı',
  ];

  static List<String> getVaccineList(String species) {
    if (species == 'Kedi') {
      return catVaccines;
    } else if (species == 'Köpek') {
      return dogVaccines;
    }
    return [];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 
import 'screens/home_screen.dart';
import 'services/notificationHelper.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  try {
    
    await NotificationHelper.init();
    
    debugPrint("Bildirim servisi başarıyla başlatıldı.");
  } catch (e) {
    debugPrint("Bildirim servisi başlatılamadı: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pati Takip',

      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],

      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.purple),
      home: const HomeScreen(), 
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'provider/user_provider.dart';
import 'theme/app_theme.dart';
import 'splash_screen1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( // Tambahkan ini
    options: DefaultFirebaseOptions.currentPlatform, // Tambahkan ini
  );
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makan Gizi Gratis',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen1(),
    );
  }
}
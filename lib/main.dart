import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_fishing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive orientation and system UI styles for Android gaming
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const JunkFishingApp());
}

class JunkFishingApp extends StatelessWidget {
  const JunkFishingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Junk Fishing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2A9D8F),
          secondary: const Color(0xFFE76F51),
          surface: const Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),
      home: const MainFishingScreen(),
    );
  }
}

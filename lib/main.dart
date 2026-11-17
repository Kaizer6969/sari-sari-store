import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/title_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen immersive mode (hides system bars on mobile & fills whole display)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Support landscape (retro widescreen arcade feel) and portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SariSariStoreApp());
}

class SariSariStoreApp extends StatelessWidget {
  const SariSariStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sari-Sari Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141F2B),
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE67E22),
          secondary: Color(0xFF2ECC71),
          surface: Color(0xFF1E272C),
        ),
      ),
      home: const TitleScreen(),
    );
  }
}

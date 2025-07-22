import 'package:flutter/material.dart';
import 'core/routes.dart';

void main() {
  runApp(const RealAudioHDApp());
}

class RealAudioHDApp extends StatelessWidget {
  const RealAudioHDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RealAudioHD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: Colors.black,
        ),
      ),
      routerConfig: router,
    );
  }
}

import 'package:eliger_driver/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EligerDriver());
}

class EligerDriver extends StatelessWidget {
  const EligerDriver({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Eliger Driver",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

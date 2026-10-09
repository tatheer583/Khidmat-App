import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080E0C),
    ),
  );
  // Paint the loading screen before opening the phone's saved records.
  runApp(const KhidmatApp());
}

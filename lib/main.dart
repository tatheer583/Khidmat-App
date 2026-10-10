import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'marketplace/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080E0C),
    ),
  );
  final marketplace = await bootstrapMarketplace();
  runApp(KhidmatApp(marketplace: marketplace));
}

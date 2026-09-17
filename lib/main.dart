import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/appwrite/appwrite_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite Client & Services
  AppwriteClient.instance.init();

  // Set immersive light status and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7F3E8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: FitTrackApp(),
    ),
  );
}

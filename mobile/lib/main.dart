import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'catalog.dart';
import 'firebase_options.dart';
import 'checklist.dart';
import 'screens/home.dart';
import 'screens/inspection.dart';
import 'screens/login.dart';
import 'screens/report.dart';
import 'screens/section.dart';
import 'screens/vehicle_form.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await Catalog.load();
  await Firebase.initializeApp(options: firebaseOptions);
  await Store.I.init();
  // Solo en modo debug: entra con la cuenta de prueba (ATLAS_TEST_EMAIL / ATLAS_TEST_PASS).
  // Se pasan al compilar: flutter run --dart-define-from-file=.dev-credentials
  const testEmail = String.fromEnvironment('ATLAS_TEST_EMAIL');
  if (kDebugMode && testEmail.isNotEmpty && Store.I.userEmail == null) {
    final err = await Store.I.login(testEmail, const String.fromEnvironment('ATLAS_TEST_PASS'));
    debugPrint('Login de prueba: ${err ?? 'ok'}');
  }
  runApp(const AtlasApp());
}

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas Motors',
      debugShowCheckedModeBanner: false,
      theme: atlasTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _debugScreen() ?? ListenableBuilder(
        listenable: Store.I,
        builder: (_, _) => Store.I.userEmail == null ? const LoginScreen() : const HomeScreen(),
      ),
    );
  }
}

/// Solo en modo debug: abre una pantalla directo para sacar capturas,
/// con la variable de entorno ATLAS_SHOT (home, form, inspection, section, report).
Widget? _debugScreen() {
  final shot = kDebugMode ? Platform.environment['ATLAS_SHOT'] : null;
  if (shot == null) return null;
  Store.I.userEmail = 'matias@atlasmotors.cl';
  final i = Store.I.inspections.first;
  return switch (shot) {
    'form' => const VehicleFormScreen(),
    'inspection' => InspectionScreen(inspection: i),
    'section' => SectionScreen(inspection: i, section: checklist.first),
    'report' => ReportScreen(inspection: i),
    _ => const HomeScreen(),
  };
}

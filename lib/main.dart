import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'components/global_values.dart';
import 'components/theme_app.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  await NotificationService.init();
  await NotificationService.reprogramar();
  await GlobalValues.actualizarCarrito();
  runApp(const AlacenaApp());
}

class AlacenaApp extends StatelessWidget {
  const AlacenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Alacena',
      debugShowCheckedModeBanner: false,
      navigatorKey: GlobalValues.navigatorKey,
      theme: ThemeApp.claro(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const DashboardScreen(),
    );
  }
}

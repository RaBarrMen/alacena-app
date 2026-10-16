import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../components/fecha_utils.dart';
import '../components/global_values.dart';
import '../database/lotes_dao.dart';
import '../screens/expiring_today_screen.dart';

/// Alarmas locales: una notificación por día de caducidad (lotes con alarma = 1)
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int horaAlarma = 9; // 9:00 a.m.
  static String? _payloadInicial;
  static final Set<int> _avisadosEnSesion = {};

  static const NotificationDetails _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'caducidad',
      'Caducidad de productos',
      channelDescription: 'Avisa los productos de la alacena que caducan cada día',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const ajustes = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(ajustes,
          onDidReceiveNotificationResponse: (r) => _abrir(r.payload));
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _payloadInicial = launch!.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint('Notificaciones no disponibles: $e');
    }
  }

  static Future<void> pedirPermisos() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Payload = fecha (yyyy-MM-dd) -> abre la pantalla "Caducan hoy"
  static void _abrir(String? payload) {
    if (payload == null || payload.isEmpty) return;
    GlobalValues.navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => ExpiringTodayScreen(fecha: DateTime.tryParse(payload)),
    ));
  }

  static void abrirSiInicioPorNotificacion() {
    final p = _payloadInicial;
    _payloadInicial = null;
    _abrir(p);
  }

  /// Se llama al iniciar y cada vez que cambia el inventario
  static Future<void> reprogramar() async {
    try {
      for (final p in await _plugin.pendingNotificationRequests()) {
        await _plugin.cancel(p.id);
      }
      // tz.local = UTC; TZDateTime.from conserva el instante exacto de la hora local
      final ahora = tz.TZDateTime.now(tz.local);
      for (final (fecha, total) in await LotesDAO.alarmasPendientes()) {
        final id = fecha.year * 10000 + fecha.month * 100 + fecha.day;
        final cuerpo = '$total artículo(s) de tu alacena caducan hoy. Toca para verlos.';
        final payload = FechaUtils.toDb(fecha);
        final cuando = tz.TZDateTime.from(
            DateTime(fecha.year, fecha.month, fecha.day, horaAlarma), tz.local);

        if (cuando.isAfter(ahora)) {
          await _plugin.zonedSchedule(
            id, 'Productos que caducan hoy', cuerpo, cuando, _detalles,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } else if (_avisadosEnSesion.add(id)) {
          // Hoy y ya pasó la hora: avisar de inmediato (una vez por sesión)
          await _plugin.show(id, 'Productos que caducan hoy', cuerpo, _detalles,
              payload: payload);
        }
      }
    } catch (e) {
      debugPrint('No se pudieron programar alarmas: $e');
    }
  }

  static Future<void> probar() => _plugin.show(
        1,
        'Prueba de alarma',
        'Toca para ver los productos que caducan hoy',
        _detalles,
        payload: FechaUtils.toDb(FechaUtils.hoy),
      );
}

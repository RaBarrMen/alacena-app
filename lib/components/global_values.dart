import 'package:flutter/material.dart';

import '../database/carrito_dao.dart';
import '../services/notification_service.dart';

class GlobalValues {
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Cantidad de bienes en el carrito (alimenta el badge)
  static final ValueNotifier<int> carritoCount = ValueNotifier<int>(0);

  /// Se incrementa cada vez que cambia el inventario para recargar pantallas
  static final ValueNotifier<int> inventario = ValueNotifier<int>(0);

  static Future<void> actualizarCarrito() async {
    carritoCount.value = await CarritoDAO.total();
  }

  static Future<void> inventarioCambio() async {
    inventario.value++;
    await NotificationService.reprogramar();
  }
}

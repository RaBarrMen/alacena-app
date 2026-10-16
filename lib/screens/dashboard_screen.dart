import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../components/fecha_utils.dart';
import '../components/global_values.dart';
import '../components/producto_tile.dart';
import '../components/status_chip.dart';
import '../database/productos_dao.dart';
import '../models/producto.dart';
import '../services/notification_service.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'day_modal.dart';
import 'expiring_today_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'products_screen.dart';
import 'stores_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ProductoResumen> _alertas = [];
  Map<DateTime, List<ProductoResumen>> _eventos = {};
  bool _cargando = true;
  int _vista = 0; // 0 = lista, 1 = calendario
  DateTime _diaEnfocado = DateTime.now();
  DateTime? _diaSeleccionado;
  CalendarFormat _formato = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _cargar();
    GlobalValues.inventario.addListener(_cargar);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.pedirPermisos();
      NotificationService.abrirSiInicioPorNotificacion();
    });
  }

  @override
  void dispose() {
    GlobalValues.inventario.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final alertas = await ProductosDAO.conAlerta();
    final eventos = <DateTime, List<ProductoResumen>>{};
    for (final a in alertas) {
      eventos.putIfAbsent(FechaUtils.soloFecha(a.fechaAlerta), () => []).add(a);
    }
    if (!mounted) return;
    setState(() {
      _alertas = alertas;
      _eventos = eventos;
      _cargando = false;
    });
  }

  List<ProductoResumen> _eventosDe(DateTime dia) =>
      _eventos[FechaUtils.soloFecha(dia)] ?? const [];

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  /// Modal a pantalla completa con los artículos del día
  void _abrirDia(DateTime dia) {
    showDialog(
      context: context,
      builder: (_) => DayModal(fecha: FechaUtils.soloFecha(dia), productos: _eventosDe(dia)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi alacena'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: GlobalValues.carritoCount,
            builder: (context, n, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: badges.Badge(
                showBadge: n > 0,
                position: badges.BadgePosition.topEnd(top: -2, end: -2),
                badgeContent: Text('$n',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                child: IconButton(
                  tooltip: 'Carrito',
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => _abrir(const CartScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _menu(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : (_vista == 0 ? _lista() : _calendario()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(const ProductFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Artículo'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _vista,
        onDestinationSelected: (i) => setState(() => _vista = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Alertas'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendario'),
        ],
      ),
    );
  }

  Widget _menu() {
    Widget item(IconData icono, String texto, Widget pantalla) => ListTile(
          leading: Icon(icono),
          title: Text(texto),
          onTap: () {
            Navigator.pop(context);
            _abrir(pantalla);
          },
        );

    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
          child: const Align(
            alignment: Alignment.bottomLeft,
            child: Text('Mi alacena',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ),
        item(Icons.inventory_2_outlined, 'Artículos', const ProductsScreen()),
        item(Icons.category_outlined, 'Categorías', const CategoriesScreen()),
        item(Icons.storefront_outlined, 'Tiendas', const StoresScreen()),
        item(Icons.event_busy, 'Caducan hoy', const ExpiringTodayScreen()),
        item(Icons.shopping_cart_outlined, 'Carrito', const CartScreen()),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Probar alarma'),
          onTap: () {
            Navigator.pop(context);
            NotificationService.probar();
          },
        ),
      ]),
    );
  }

  Widget _lista() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: LeyendaEstatus(conteo: ProductoResumen.contar(_alertas)),
          ),
          if (_alertas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('Todo en orden: nada por caducar o agotarse.')),
            )
          else
            ..._alertas.map((a) => ProductoTile(
                  item: a,
                  onTap: () => _abrir(ProductDetailScreen(productoId: a.producto.id!)),
                )),
        ],
      ),
    );
  }

  Widget _calendario() {
    return ListView(padding: const EdgeInsets.only(bottom: 88), children: [
      TableCalendar<ProductoResumen>(
        locale: 'es_MX',
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2035, 12, 31),
        focusedDay: _diaEnfocado,
        calendarFormat: _formato,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mes',
          CalendarFormat.twoWeeks: '2 semanas',
          CalendarFormat.week: 'Semana',
        },
        selectedDayPredicate: (d) => isSameDay(_diaSeleccionado, d),
        eventLoader: _eventosDe, // un evento (punto) por producto con alerta
        onDaySelected: (sel, foc) {
          setState(() {
            _diaSeleccionado = sel;
            _diaEnfocado = foc;
          });
          _abrirDia(sel);
        },
        onFormatChanged: (f) => setState(() => _formato = f),
        onPageChanged: (foc) => _diaEnfocado = foc,
        calendarBuilders: CalendarBuilders<ProductoResumen>(
          // Un punto por producto, con el color de su estatus
          markerBuilder: (context, day, eventos) {
            if (eventos.isEmpty) return null;
            return Positioned(
              bottom: 4,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final e in eventos.take(8))
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: e.estatus.color),
                  ),
              ]),
            );
          },
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Cada punto es un artículo con alerta ese día (color = estatus). '
            'Toca un día para ver el detalle.'),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: LeyendaEstatus(),
      ),
    ]);
  }
}

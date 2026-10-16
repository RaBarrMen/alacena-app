import 'package:intl/intl.dart';

class FechaUtils {
  static DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime get hoy => soloFecha(DateTime.now());

  /// Formato ISO usado en la BD (yyyy-MM-dd)
  static String toDb(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static DateTime fromDb(String s) => soloFecha(DateTime.parse(s));

  static String corta(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String larga(DateTime d) =>
      DateFormat("EEEE d 'de' MMMM 'de' y", 'es_MX').format(d);

  static int diasHasta(DateTime d) =>
      (soloFecha(d).difference(hoy).inHours / 24).round();

  static String textoCaducidad(DateTime d) {
    final n = diasHasta(d);
    if (n < 0) return 'Caducó hace ${-n} día(s) (${corta(d)})';
    if (n == 0) return 'Caduca hoy';
    return 'Caduca en $n día(s) (${corta(d)})';
  }
}

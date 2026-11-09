import 'package:intl/intl.dart';

/// Formatea los importes de los eventos, que **son en pesos colombianos**
/// desde el 2026-11-09 (pedido del usuario). Del 2026-08-20 hasta esa fecha
/// eran en dólares y se mostraban con «USD» delante.
///
/// La moneda va siempre escrita y **delante** —«COP $150.000»—: con un «$»
/// suelto no se sabe de qué moneda es la cifra, y en la app conviven precios
/// en pesos con los de LSO, que son en dólares.
class CurrencyFormatter {
  /// Ejemplos: `0` → `GRATIS`; `499` → `COP $499`; `150000` → `COP $150.000`.
  static String format(double amount) {
    if (amount == 0) return 'GRATIS';

    // Agrupación de miles con punto, como se escribe en Colombia. Sin
    // decimales: los pesos no usan centavos.
    final miles = NumberFormat.decimalPattern('es_CO')
      ..maximumFractionDigits = 0;

    return 'COP \$${miles.format(amount)}';
  }

  /// Alias for clarify what we are formatting
  static String formatPrice(double price) => format(price);
}

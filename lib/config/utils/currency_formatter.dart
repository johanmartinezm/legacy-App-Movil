import 'package:intl/intl.dart';

/// Formatea los importes de los eventos, que **se cobran en dólares**
/// —confirmado por el cliente el 2026-08-20—.
///
/// Hasta esa fecha usaba `NumberFormat.currency` con locale `es_CO` y símbolo
/// `$`, así que un evento de 499 dólares se veía como «499 $»: la cifra sin
/// decir de qué moneda, con formato colombiano y junto a contenido en pesos.
/// Un summit a 499 pesos son doce centavos de dólar, y nada en la pantalla
/// permitía distinguirlo.
///
/// La moneda va **delante** —«USD $499»—, igual que en los programas de LSO
/// (`GraphqlProgram.precioConMoneda`), para que siga leyéndose si la cifra
/// queda justa de sitio. Las dos superficies con precio de la app dicen la
/// moneda de la misma forma.
class CurrencyFormatter {
  /// Ejemplos: `0` → `GRATIS`; `499` → `USD $499`; `150000` → `USD $150.000`.
  static String format(double amount) {
    if (amount == 0) return 'GRATIS';

    // Agrupación de miles con punto, como se escribe en Colombia y en la
    // tienda de LSO. Sin decimales: los precios son importes redondos.
    final miles = NumberFormat.decimalPattern('es_CO')
      ..maximumFractionDigits = 0;

    return 'USD \$${miles.format(amount)}';
  }

  /// Alias for clarify what we are formatting
  static String formatPrice(double price) => format(price);
}

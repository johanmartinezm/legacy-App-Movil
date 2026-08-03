import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats a double amount into a currency string (standard COP format).
  /// Example: 3150000 -> $ 3.150.000
  static String format(double amount) {
    if (amount == 0) return 'GRATIS';
    
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$ ',
      decimalDigits: 0,
    );
    
    return formatter.format(amount);
  }

  /// Alias for clarify what we are formatting
  static String formatPrice(double price) => format(price);
}

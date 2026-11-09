import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/config/utils/currency_formatter.dart';

/// Los eventos son en pesos colombianos desde el 2026-11-09 (antes, dólares).
/// La moneda va siempre escrita: con un «$» suelto no se sabe cuál es.
void main() {
  group('la moneda se dice siempre', () {
    test('un importe normal lleva COP delante', () {
      expect(CurrencyFormatter.format(499), 'COP \$499');
      expect(CurrencyFormatter.format(25), 'COP \$25');
    });

    test('los miles se agrupan con punto', () {
      expect(CurrencyFormatter.format(150000), 'COP \$150.000');
      expect(CurrencyFormatter.format(1500), 'COP \$1.500');
    });

    test('sin decimales: los pesos no usan centavos', () {
      expect(CurrencyFormatter.format(499.4), 'COP \$499');
      expect(CurrencyFormatter.format(499.6), 'COP \$500');
    });
  });

  group('gratis no es un precio', () {
    // Un evento gratuito no dice «COP $0»: dice que es gratis.
    test('cero se anuncia como GRATIS, sin moneda', () {
      expect(CurrencyFormatter.format(0), 'GRATIS');
    });

    test('formatPrice se comporta igual', () {
      expect(CurrencyFormatter.formatPrice(0), 'GRATIS');
      expect(CurrencyFormatter.formatPrice(499), 'COP \$499');
    });
  });
}

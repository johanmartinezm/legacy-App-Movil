import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/config/utils/currency_formatter.dart';

/// Los eventos se cobran en dólares —confirmado por el cliente el 2026-08-20—.
/// Antes se formateaban con locale colombiano y un «$» suelto, así que el
/// Legacy Summit de 499 dólares se leía como 499 pesos: doce centavos.
void main() {
  group('la moneda se dice siempre', () {
    test('un importe normal lleva USD delante', () {
      expect(CurrencyFormatter.format(499), 'USD \$499');
      expect(CurrencyFormatter.format(25), 'USD \$25');
    });

    test('los miles se agrupan con punto', () {
      expect(CurrencyFormatter.format(150000), 'USD \$150.000');
      expect(CurrencyFormatter.format(1500), 'USD \$1.500');
    });

    test('sin decimales: los precios son importes redondos', () {
      expect(CurrencyFormatter.format(499.4), 'USD \$499');
      expect(CurrencyFormatter.format(499.6), 'USD \$500');
    });
  });

  group('gratis no es un precio', () {
    // Un evento gratuito no dice «USD $0»: dice que es gratis.
    test('cero se anuncia como GRATIS, sin moneda', () {
      expect(CurrencyFormatter.format(0), 'GRATIS');
    });

    test('formatPrice se comporta igual', () {
      expect(CurrencyFormatter.formatPrice(0), 'GRATIS');
      expect(CurrencyFormatter.formatPrice(499), 'USD \$499');
    });
  });
}

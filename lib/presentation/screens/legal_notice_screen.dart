import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/documentos_legales_enlaces.dart';

class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos Legales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Términos y Condiciones',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      // Lo que sigue es un resumen: los documentos publicados
                      // son los que rigen, y decirlo evita que este texto —tres
                      // secciones frente a las dieciséis del documento real—
                      // parezca el contrato completo.
                      const Text(
                        'Este es un resumen. Los documentos completos y vigentes son los publicados por Legacy Network:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      const DocumentosLegalesEnlaces(fontSize: 13),
                      const SizedBox(height: 24),
                      _SectionTitle(context, '1. Habeas Data y Privacidad'),
                      const SizedBox(height: 8),
                      const Text(
                        'De conformidad con la normativa vigente sobre protección de datos personales (Habeas Data), al registrarse en esta aplicación, usted autoriza expresamente a Legacy App a recolectar, almacenar y tratar sus datos personales. Estos datos serán utilizados exclusivamente para la prestación de los servicios ofrecidos, mejoras en la experiencia de usuario y comunicaciones relacionadas. Usted tiene derecho a conocer, actualizar y rectificar sus datos personales solicitándolo a través de nuestros canales de atención.',
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(context, '2. Exención de Responsabilidad'),
                      const SizedBox(height: 8),
                      const Text(
                        'Legacy App implementa mecanismos de seguridad estándar en la industria para proteger su información y la integridad del software. Sin embargo, el usuario reconoce y acepta que el uso de la tecnología conlleva riesgos inherentes y que ningún sistema es infalible.\n\nLegacy App no se hace responsable por:',
                      ),
                      const SizedBox(height: 8),
                      _BulletPoint('Interrupciones, fallos o errores en el funcionamiento del software.'),
                      _BulletPoint('Pérdida de datos derivada de causas de fuerza mayor o uso inadecuado.'),
                      _BulletPoint('Accesos no autorizados o vulneraciones de seguridad que escapen a nuestro control razonable, a pesar de las medidas de seguridad implementadas.'),
                      _BulletPoint('Daños y perjuicios directos, indirectos, incidentales o consecuentes que puedan derivarse del uso de la aplicación.'),
                      const SizedBox(height: 24),
                      _SectionTitle(context, '3. Aceptación'),
                      const SizedBox(height: 8),
                      const Text(
                        'Al hacer clic en "Aceptar y Continuar", usted declara haber leído, entendido y aceptado estos términos y condiciones en su totalidad.',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.push('/profile-selection');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Aceptar y Continuar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final BuildContext context;
  final String title;

  const _SectionTitle(this.context, this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

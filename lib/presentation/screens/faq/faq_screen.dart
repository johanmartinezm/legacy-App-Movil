import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/faq_data.dart';
import '../../../domain/utils/busqueda_global.dart';

/// Preguntas frecuentes, en cuatro secciones.
///
/// Lleva buscador porque una lista de dieciséis preguntas plegadas es incómoda
/// de recorrer con el pulgar, y quien entra aquí casi siempre trae una duda
/// concreta. Reutiliza `normalizar` de la búsqueda global: buscar "notificacion"
/// sin tilde también encuentra.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _controladorBusqueda = TextEditingController();
  String _consulta = '';

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  /// Filtra por pregunta y por respuesta, y descarta las secciones que se
  /// quedan sin nada.
  List<SeccionFaq> get _secciones {
    final palabras = normalizar(_consulta).split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.isEmpty) return seccionesFaq;

    final filtradas = <SeccionFaq>[];
    for (final seccion in seccionesFaq) {
      final coinciden = seccion.preguntas.where((p) {
        final texto = normalizar('${p.pregunta} ${p.respuesta}');
        return palabras.every(texto.contains);
      }).toList();
      if (coinciden.isNotEmpty) filtradas.add(SeccionFaq(seccion.titulo, coinciden));
    }
    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    final secciones = _secciones;
    final buscando = _consulta.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas frecuentes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controladorBusqueda,
                onChanged: (valor) => setState(() => _consulta = valor),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar una duda',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: buscando
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Limpiar',
                          onPressed: () {
                            _controladorBusqueda.clear();
                            setState(() => _consulta = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: secciones.isEmpty
                  ? _sinResultados(context)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        for (final seccion in secciones) ..._bloqueDeSeccion(context, seccion, buscando),
                        const SizedBox(height: 24),
                        _pieDeAyuda(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bloqueDeSeccion(BuildContext context, SeccionFaq seccion, bool buscando) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          seccion.titulo.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
      for (final p in seccion.preguntas)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            // Al buscar, las coincidencias salen abiertas: si hay que tocar
            // cada una para ver si es la buena, el buscador no ahorra nada.
            key: ValueKey('${p.pregunta}-$buscando'),
            initiallyExpanded: buscando,
            title: Text(
              p.pregunta,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.respuesta, style: const TextStyle(fontSize: 14, height: 1.45)),
            ],
          ),
        ),
    ];
  }

  Widget _sinResultados(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40),
            const SizedBox(height: 16),
            Text(
              'Ninguna pregunta coincide con "${_consulta.trim()}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escríbenos y resolvemos tu duda directamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/contacto'),
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Contáctenos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieDeAyuda(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.support_agent_outlined),
        title: const Text('¿No encuentras lo que buscas?'),
        subtitle: const Text('Escríbenos y te respondemos al correo de tu cuenta'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/contacto'),
      ),
    );
  }
}

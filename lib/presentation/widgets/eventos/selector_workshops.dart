import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/models/workshop_model.dart';
import '../../../domain/utils/franjas_workshops.dart';

const _cian = Color(0xFF00F2FE);
const _textoSecundario = Color(0xFF9FB2C2);

/// Abre la hoja para elegir los workshops de un evento, uno por franja (§10 del
/// plan de workshops). Devuelve los ids elegidos, o null si se cerró sin
/// continuar.
///
/// Con [soloLectura] muestra lo elegido sin dejar cambiarlo: es lo que se ve
/// desde el primer día del evento, cuando la elección ya cerró.
Future<List<String>?> elegirWorkshops(
  BuildContext context, {
  required List<WorkshopModel> workshops,
  Set<String> elegidos = const {},
  String textoBoton = 'Continuar',
  bool soloLectura = false,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.legacyBlue1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SelectorWorkshops(
      workshops: workshops,
      elegidos: elegidos,
      textoBoton: textoBoton,
      soloLectura: soloLectura,
    ),
  );
}

class SelectorWorkshops extends StatefulWidget {
  final List<WorkshopModel> workshops;
  final Set<String> elegidos;
  final String textoBoton;
  final bool soloLectura;

  const SelectorWorkshops({
    super.key,
    required this.workshops,
    this.elegidos = const {},
    this.textoBoton = 'Continuar',
    this.soloLectura = false,
  });

  @override
  State<SelectorWorkshops> createState() => _SelectorWorkshopsState();
}

class _SelectorWorkshopsState extends State<SelectorWorkshops> {
  late final List<FranjaWorkshops> _franjas;

  /// Índice de la franja → id del workshop elegido en ella.
  final Map<int, String> _elegido = {};

  @override
  void initState() {
    super.initState();
    _franjas = calcularFranjas(widget.workshops);
    for (var i = 0; i < _franjas.length; i++) {
      final ws = _franjas[i].workshops;
      final previo = ws.where((w) => widget.elegidos.contains(w.id));
      if (previo.isNotEmpty) {
        _elegido[i] = previo.first.id;
      } else if (ws.length == 1 && !widget.soloLectura) {
        // Una franja con un solo workshop no tiene nada que elegir.
        _elegido[i] = ws.single.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final motivo = motivoEleccionIncompleta(_franjas, _elegido);
    final alto = MediaQuery.of(context).size.height * 0.88;

    return SizedBox(
      height: alto,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _textoSecundario.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.soloLectura ? 'Mis workshops' : 'Elige tus workshops',
                  style: GoogleFonts.barlow(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.soloLectura
                      ? 'La elección cerró al empezar el evento.'
                      : 'Uno en cada horario. Podrás cambiarlos hasta el día '
                            'anterior al evento.',
                  style: GoogleFonts.questrial(
                    fontSize: 14,
                    color: _textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              children: _construirFranjas(),
            ),
          ),
          if (!widget.soloLectura) _pie(motivo),
        ],
      ),
    );
  }

  List<Widget> _construirFranjas() {
    final hijos = <Widget>[];
    String? diaAnterior;
    for (var i = 0; i < _franjas.length; i++) {
      final f = _franjas[i];
      if (f.dia != diaAnterior) {
        diaAnterior = f.dia;
        hijos.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              _capitalizar(
                DateFormat(
                  "EEEE d 'de' MMMM",
                  'es',
                ).format(enColombia(f.inicio)),
              ),
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _cian,
              ),
            ),
          ),
        );
      }
      hijos.add(_franja(i, f));
    }
    return hijos;
  }

  Widget _franja(int indice, FranjaWorkshops f) {
    final opciones = widget.soloLectura
        ? f.workshops.where((w) => _elegido[indice] == w.id).toList()
        : f.workshops;

    return Container(
      key: Key('franja-$indice'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.legacySurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _elegido.containsKey(indice)
              ? AppTheme.legacyActive.withValues(alpha: 0.6)
              : AppTheme.legacyBlue2.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              f.horario,
              style: GoogleFonts.barlow(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: _textoSecundario,
              ),
            ),
          ),
          if (opciones.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                'No elegiste ninguno en este horario.',
                style: GoogleFonts.questrial(color: _textoSecundario),
              ),
            ),
          ...opciones.map((w) => _opcion(indice, w)),
        ],
      ),
    );
  }

  Widget _opcion(int indice, WorkshopModel w) {
    final detalle = [
      w.room,
      w.speaker,
    ].where((t) => t.trim().isNotEmpty).join(' · ');
    final marcado = _elegido[indice] == w.id;

    return InkWell(
      key: Key('workshop-${w.id}'),
      onTap: widget.soloLectura
          ? null
          : () => setState(() => _elegido[indice] = w.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
        child: Row(
          children: [
            Icon(
              widget.soloLectura
                  ? Icons.check_circle
                  : (marcado
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
              color: marcado ? _cian : _textoSecundario,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: GoogleFonts.barlow(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (detalle.isNotEmpty)
                    Text(
                      detalle,
                      style: GoogleFonts.barlow(
                        fontSize: 13,
                        color: _textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pie(String? motivo) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: BoxDecoration(
          color: AppTheme.legacyBlue1,
          border: Border(
            top: BorderSide(color: AppTheme.legacyBlue2.withValues(alpha: 0.6)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (motivo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  motivo,
                  key: const Key('selector-motivo'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.questrial(
                    fontSize: 13,
                    color: _textoSecundario,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('selector-continuar'),
                onPressed: motivo != null
                    ? null
                    : () => Navigator.of(context).pop(_elegido.values.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.legacyActive,
                  foregroundColor: const Color(0xFF162540),
                  disabledBackgroundColor: AppTheme.legacyBlue2,
                  disabledForegroundColor: _textoSecundario,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.textoBoton,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalizar(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

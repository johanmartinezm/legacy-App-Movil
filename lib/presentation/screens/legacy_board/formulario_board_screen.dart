import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/board_formularios_service.dart';
import '../../../data/services/solo_plus.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/utils/validacion_formulario_board.dart';
import '../../../domain/utils/volver_atras.dart';
import '../../widgets/boton_volver.dart';
import 'campo_board_widget.dart';

/// El motor de formularios de Legacy Board: pinta cualquier formulario a
/// partir de la configuración que manda el backend, una sección por paso.
///
/// Si la persona ya lo envió, muestra el estado de su envío en vez del
/// formulario: en la app no se edita ni se reenvía nada (decisión 5 del plan
/// reports/20261002_plan_legacy_board_formularios.md).
class FormularioBoardScreen extends StatefulWidget {
  /// «A» (postulación del consejero) o «B» (solicitud del empresario).
  final String clave;
  final BoardFormulariosService? servicio;

  const FormularioBoardScreen({super.key, required this.clave, this.servicio});

  @override
  State<FormularioBoardScreen> createState() => _FormularioBoardScreenState();
}

class _FormularioBoardScreenState extends State<FormularioBoardScreen> {
  late final BoardFormulariosService _servicio = widget.servicio ?? BoardFormulariosService();
  final _scroll = ScrollController();

  FormularioBoard? _formulario;
  bool _cargando = true;
  String? _errorCarga;
  bool _soloPlus = false;

  final Map<String, dynamic> _valores = {};
  final Map<String, String> _errores = {};
  bool _aceptaTerminos = false;
  String? _errorTerminos;
  int _paso = 0;
  bool _enviando = false;
  bool _tocado = false;
  EnvioBoard? _enviado;

  /// La persona eligió empezar una solicitud nueva tras una ya decidida.
  bool _nuevo = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String? get _token => Provider.of<AuthProvider>(context, listen: false).token;

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
      _soloPlus = false;
    });
    try {
      final f = await _servicio.formulario(_token, widget.clave);
      if (!mounted) return;
      _prellenar(f);
      setState(() {
        _formulario = f;
        _cargando = false;
      });
    } on SoloPlusException {
      if (!mounted) return;
      setState(() {
        _soloPlus = true;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorCarga = 'No se pudo abrir el formulario. Revisa tu conexión e inténtalo de nuevo.';
        _cargando = false;
      });
    }
  }

  /// Llena con el perfil lo que el formulario pide prellenar. Se puede cambiar.
  void _prellenar(FormularioBoard f) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final perfil = <String, String?>{
      'nombre': auth.fullName,
      'correo': auth.email,
      'telefono': auth.phone,
      'foto': (auth.fotoPerfil ?? '').startsWith('/api/images/') ? auth.fotoPerfil : null,
    };
    for (final s in f.secciones) {
      for (final c in s.campos) {
        final dato = perfil[c.prellenar]?.trim();
        if (c.prellenar.isNotEmpty && dato != null && dato.isNotEmpty) {
          _valores[c.clave] = dato;
        }
      }
    }
  }

  void _cambiar(CampoBoard campo, dynamic valor) {
    setState(() {
      _valores[campo.clave] = valor;
      _tocado = true;
      // El error se va en cuanto se corrige; no se vuelve a evaluar hasta el
      // siguiente «Siguiente», para no regañar mientras se escribe.
      if (_errores.containsKey(campo.clave) && validarCampoBoard(campo, valor) == null) {
        _errores.remove(campo.clave);
      }
    });
  }

  bool _validarPaso(int paso) {
    final seccion = _formulario!.secciones[paso];
    for (final c in seccion.campos) {
      final error = validarCampoBoard(c, _valores[c.clave]);
      if (error == null) {
        _errores.remove(c.clave);
      } else {
        _errores[c.clave] = error;
      }
    }
    return seccion.campos.every((c) => !_errores.containsKey(c.clave));
  }

  void _irA(int paso) {
    setState(() => _paso = paso);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _siguiente() {
    final ok = _validarPaso(_paso);
    setState(() {});
    if (!ok) {
      _avisar('Revisa los campos marcados en rojo.');
      return;
    }
    _irA(_paso + 1);
  }

  Future<void> _enviar() async {
    final f = _formulario!;
    // Todas las secciones, por si algo cambió al volver atrás.
    for (var i = 0; i < f.secciones.length; i++) {
      if (!_validarPaso(i)) {
        setState(() {});
        _irA(i);
        _avisar('Revisa los campos marcados en rojo.');
        return;
      }
    }
    if (!_aceptaTerminos) {
      setState(() => _errorTerminos = 'Debes aceptar para enviar');
      return;
    }

    setState(() => _enviando = true);
    try {
      final envio = await _servicio.enviar(
        _token,
        widget.clave,
        respuestas: respuestasParaEnviarBoard(f, _valores),
        aceptaTerminos: _aceptaTerminos,
      );
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _enviado = envio;
      });
    } on ErrorFormularioBoard catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      if (e.yaEnviado) {
        // Lo envió desde otro sitio: recargar muestra su estado.
        _avisar(e.mensaje);
        _cargar();
        return;
      }
      final seccion = e.campo == null ? -1 : seccionDelCampoBoard(f, e.campo!);
      if (seccion >= 0) {
        setState(() => _errores[e.campo!] = e.mensaje);
        _irA(seccion);
      } else if (e.campo == 'acepta_terminos') {
        setState(() => _errorTerminos = e.mensaje);
      }
      _avisar(e.mensaje);
    } on SoloPlusException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _avisar(e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      // Las respuestas siguen ahí: perderlas sería lo peor de un fallo de red.
      _avisar('No se pudo enviar. Revisa tu conexión e inténtalo de nuevo; tus respuestas se conservan.');
    }
  }

  /// Flotante y por encima de los botones: abajo del todo tapaba «Siguiente»
  /// justo cuando la persona iba a tocarlo otra vez tras corregir.
  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ));
  }

  Future<void> _salir() async {
    if (!_tocado || _enviado != null || (_formulario?.envioActual != null && !_nuevo)) {
      volverAtras(context, destino: '/legacy-board');
      return;
    }
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Salir sin enviar?'),
        content: const Text('Se perderán las respuestas que llevas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Seguir llenando')),
          TextButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Salir')),
        ],
      ),
    );
    if (salir == true && mounted) volverAtras(context, destino: '/legacy-board');
  }

  @override
  Widget build(BuildContext context) {
    final f = _formulario;
    return PopScope(
      canPop: !_tocado || _enviado != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(f?.titulo ?? 'Legacy Board'),
          leading: BotonVolver(onTap: _salir),
        ),
        body: SafeArea(child: _cuerpo(context)),
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_soloPlus) {
      return _mensaje(context, Icons.lock_outline, 'Solo para usuarios Legacy+',
          'Este formulario se habilita a los usuarios Legacy+. Si crees que deberías tenerlo, escríbenos desde Contáctenos.');
    }
    if (_errorCarga != null) {
      return _mensaje(context, Icons.wifi_off_outlined, 'No se pudo cargar', _errorCarga!, reintentar: true);
    }
    final f = _formulario!;
    if (_enviado != null) {
      return _mensaje(context, Icons.mark_email_read_outlined, '¡Enviado!',
          f.textoConfirmacion.isEmpty ? 'Recibimos tu formulario.' : f.textoConfirmacion,
          envio: _enviado);
    }
    final actual = f.envioActual;
    // Con uno pendiente, o en un formulario que no admite otro (el A), solo
    // se ve el estado. Con uno ya decidido del B, el estado y la opción de
    // empezar otra solicitud.
    if (actual != null && !_nuevo) {
      final puedeOtro = f.permiteNuevo && actual.estado != 'pendiente';
      return _estado(context, actual, puedeOtro: puedeOtro);
    }
    return _pasoActual(context, f);
  }

  Widget _mensaje(BuildContext context, IconData icono, String titulo, String texto,
      {bool reintentar = false, EnvioBoard? envio, bool otraVez = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(icono, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
          if (envio != null) ...[const SizedBox(height: 24), Center(child: _chipEstado(context, envio.estado))],
          const SizedBox(height: 32),
          if (reintentar) FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
          if (otraVez) ...[
            FilledButton(
              key: const Key('board-nueva-solicitud'),
              onPressed: () => setState(() {
                _nuevo = true;
                _paso = 0;
              }),
              child: const Text('Hacer una nueva solicitud'),
            ),
            const SizedBox(height: 8),
          ],
          if (!reintentar && !otraVez)
            FilledButton(onPressed: () => volverAtras(context, destino: '/legacy-board'), child: const Text('Volver')),
          if (otraVez)
            OutlinedButton(onPressed: () => volverAtras(context, destino: '/legacy-board'), child: const Text('Volver')),
        ],
      ),
    );
  }

  static const _textosEstado = {
    'pendiente': ('En revisión', 'El comité de curaduría está revisando tu envío. Te avisaremos de su decisión.'),
    'aprobada': ('Aprobada', 'El comité aprobó tu envío.'),
    'rechazada': ('No aprobada', 'El comité revisó tu envío y esta vez no fue aprobado.'),
  };

  Widget _chipEstado(BuildContext context, String estado) {
    final color = switch (estado) {
      'aprobada' => Colors.green,
      'rechazada' => Theme.of(context).colorScheme.error,
      _ => Colors.amber.shade700,
    };
    return Chip(
      key: const Key('board-estado'),
      avatar: Icon(
        estado == 'aprobada'
            ? Icons.check_circle_outline
            : estado == 'rechazada'
                ? Icons.cancel_outlined
                : Icons.hourglass_top,
        color: color,
      ),
      label: Text(_textosEstado[estado]?.$1 ?? estado),
      side: BorderSide(color: color),
    );
  }

  Widget _estado(BuildContext context, EnvioBoard envio, {bool puedeOtro = false}) {
    final fecha = envio.creadoEn;
    final enviado = fecha == null ? '' : ' el ${fecha.day}/${fecha.month}/${fecha.year}';
    return _mensaje(
      context,
      Icons.assignment_turned_in_outlined,
      puedeOtro ? 'Tu última solicitud$enviado' : 'Ya enviaste este formulario$enviado',
      _textosEstado[envio.estado]?.$2 ?? '',
      envio: envio,
      otraVez: puedeOtro,
    );
  }

  Widget _pasoActual(BuildContext context, FormularioBoard f) {
    final total = f.secciones.length;
    final seccion = f.secciones[_paso];
    final ultimo = _paso == total - 1;
    final tema = Theme.of(context);

    return Column(
      children: [
        LinearProgressIndicator(value: (_paso + 1) / total),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_paso == 0 && f.descripcion.isNotEmpty) ...[
                  Text(f.descripcion, style: tema.textTheme.bodyMedium),
                  const SizedBox(height: 20),
                ],
                Text('Paso ${_paso + 1} de $total', style: tema.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(seccion.titulo,
                    style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                for (final campo in seccion.campos) ...[
                  CampoBoardWidget(
                    // La clave incluye el paso para que, al volver a la sección,
                    // cada campo arranque con el valor guardado.
                    key: ValueKey('${_paso}_${campo.clave}'),
                    campo: campo,
                    valor: _valores[campo.clave],
                    error: _errores[campo.clave],
                    onChanged: (v) => _cambiar(campo, v),
                    subirFoto: (ruta) => _servicio.subirFoto(_token, ruta),
                  ),
                  const SizedBox(height: 20),
                ],
                if (ultimo)
                  CheckboxListTile(
                    key: const Key('board-acepta-terminos'),
                    value: _aceptaTerminos,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(f.textoTerminos.isEmpty
                        ? 'Acepto los términos y el tratamiento de mis datos personales.'
                        : f.textoTerminos),
                    subtitle: _errorTerminos == null
                        ? null
                        : Text(_errorTerminos!, style: TextStyle(color: tema.colorScheme.error)),
                    onChanged: (v) => setState(() {
                      _aceptaTerminos = v ?? false;
                      _tocado = true;
                      if (_aceptaTerminos) _errorTerminos = null;
                    }),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              if (_paso > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enviando ? null : () => _irA(_paso - 1),
                    child: const Text('Anterior'),
                  ),
                ),
              if (_paso > 0) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('board-siguiente'),
                  onPressed: _enviando ? null : (ultimo ? _enviar : _siguiente),
                  child: _enviando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(ultimo ? 'Enviar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

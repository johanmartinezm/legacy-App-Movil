import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/config/api_constants.dart';
import '../../../data/services/board_formularios_service.dart';

/// Un campo de un formulario de Legacy Board, pintado según su tipo. No guarda
/// el valor: lo recibe y avisa con [onChanged], y la pantalla lo conserva al
/// pasar de una sección a otra.
class CampoBoardWidget extends StatefulWidget {
  final CampoBoard campo;
  final dynamic valor;
  final String? error;
  final ValueChanged<dynamic> onChanged;

  /// Solo para el tipo foto: sube el archivo y devuelve la ruta a guardar.
  final Future<String> Function(String rutaArchivo)? subirFoto;

  const CampoBoardWidget({
    super.key,
    required this.campo,
    required this.valor,
    required this.onChanged,
    this.error,
    this.subirFoto,
  });

  @override
  State<CampoBoardWidget> createState() => _CampoBoardWidgetState();
}

class _CampoBoardWidgetState extends State<CampoBoardWidget> {
  TextEditingController? _texto;
  bool _subiendo = false;

  CampoBoard get _campo => widget.campo;

  static const _tiposDeTexto = {
    TipoCampoBoard.texto,
    TipoCampoBoard.textoLargo,
    TipoCampoBoard.email,
    TipoCampoBoard.telefono,
    TipoCampoBoard.url,
  };

  bool get _numeroEnLista =>
      _campo.tipo == TipoCampoBoard.numero &&
      _campo.min != null &&
      _campo.max != null &&
      _campo.max! - _campo.min! <= 12;

  @override
  void initState() {
    super.initState();
    if (_tiposDeTexto.contains(_campo.tipo) || (_campo.tipo == TipoCampoBoard.numero && !_numeroEnLista)) {
      _texto = TextEditingController(text: widget.valor == null ? '' : '${widget.valor}');
    }
  }

  @override
  void dispose() {
    _texto?.dispose();
    super.dispose();
  }

  String get _etiqueta => _campo.obligatorio ? _campo.etiqueta : '${_campo.etiqueta} (opcional)';

  /// Una etiqueta así no cabe en el borde de la caja en un teléfono: se
  /// cortaría con «…» y no se sabría qué se pregunta (pasó con la de
  /// programas de formación). Esas van como texto encima.
  bool get _etiquetaLarga => _etiqueta.length > 48;

  InputDecoration _decoracion({String? hint}) => InputDecoration(
        labelText: _etiquetaLarga ? null : _etiqueta,
        hintText: hint,
        helperText: _campo.ayuda.isEmpty ? null : _campo.ayuda,
        helperMaxLines: 3,
        errorText: widget.error,
        errorMaxLines: 3,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final campo = _campoSegunTipo(context);
    if (!_etiquetaLarga) return campo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_etiqueta, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        campo,
      ],
    );
  }

  Widget _campoSegunTipo(BuildContext context) {
    switch (_campo.tipo) {
      case TipoCampoBoard.seleccion:
        return _seleccion();
      case TipoCampoBoard.multiseleccion:
        return _multiseleccion(context);
      case TipoCampoBoard.siNo:
        return _siNo(context);
      case TipoCampoBoard.fecha:
        return _fecha(context);
      case TipoCampoBoard.foto:
        return _foto(context);
      case TipoCampoBoard.numero:
        return _numeroEnLista ? _numeroLista() : _textoLibre();
      default:
        return _textoLibre();
    }
  }

  Widget _textoLibre() {
    final largo = _campo.tipo == TipoCampoBoard.textoLargo;
    final teclado = switch (_campo.tipo) {
      TipoCampoBoard.email => TextInputType.emailAddress,
      TipoCampoBoard.telefono => TextInputType.phone,
      TipoCampoBoard.url => TextInputType.url,
      TipoCampoBoard.numero => TextInputType.number,
      _ => largo ? TextInputType.multiline : TextInputType.text,
    };
    return TextFormField(
      key: Key('board-${_campo.clave}'),
      controller: _texto,
      keyboardType: teclado,
      minLines: largo ? 4 : 1,
      maxLines: largo ? 10 : 1,
      maxLength: _campo.tipo == TipoCampoBoard.numero ? 2 : _campo.maximoTexto,
      // El contador solo en los largos, donde el límite se alcanza de verdad.
      buildCounter: largo
          ? null
          : (context, {required currentLength, required isFocused, maxLength}) => null,
      inputFormatters: _campo.tipo == TipoCampoBoard.numero ? [FilteringTextInputFormatter.digitsOnly] : null,
      textCapitalization: _campo.tipo == TipoCampoBoard.texto || largo
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      autocorrect: !(_campo.tipo == TipoCampoBoard.email || _campo.tipo == TipoCampoBoard.url),
      decoration: _decoracion(hint: _campo.tipo == TipoCampoBoard.url ? 'https://' : null),
      onChanged: (v) => widget.onChanged(
        _campo.tipo == TipoCampoBoard.numero ? int.tryParse(v) : v,
      ),
    );
  }

  Widget _numeroLista() {
    final actual = widget.valor is int ? widget.valor as int : null;
    return DropdownButtonFormField<int>(
      key: Key('board-${_campo.clave}'),
      initialValue: actual,
      isExpanded: true,
      decoration: _decoracion(),
      items: [
        for (var n = _campo.min!; n <= _campo.max!; n++) DropdownMenuItem(value: n, child: Text('$n')),
      ],
      onChanged: widget.onChanged,
    );
  }

  Widget _seleccion() {
    final actual = _campo.opciones.any((o) => o.id == widget.valor) ? widget.valor as String : null;
    return DropdownButtonFormField<String>(
      key: Key('board-${_campo.clave}'),
      initialValue: actual,
      isExpanded: true,
      decoration: _decoracion(),
      items: [
        for (final o in _campo.opciones)
          DropdownMenuItem(value: o.id, child: Text(o.etiqueta, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: widget.onChanged,
    );
  }

  /// Envuelve los campos que no son un TextField para que tengan el mismo
  /// marco, etiqueta, ayuda y error que los demás.
  Widget _marco(BuildContext context, Widget hijo) {
    return InputDecorator(
      decoration: _decoracion().copyWith(contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12)),
      isEmpty: false,
      child: hijo,
    );
  }

  Widget _multiseleccion(BuildContext context) {
    final elegidos = widget.valor is List ? (widget.valor as List).cast<String>() : const <String>[];
    return _marco(
      context,
      Wrap(
        key: Key('board-${_campo.clave}'),
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in _campo.opciones)
            FilterChip(
              label: Text(o.etiqueta),
              selected: elegidos.contains(o.id),
              onSelected: (marcar) {
                var nueva = [...elegidos];
                if (marcar) {
                  // La opción exclusiva («No aplica») limpia las demás, y
                  // cualquier otra quita la exclusiva: así la regla no llega
                  // a saltar como error.
                  if (o.codigo == _campo.exclusiva) {
                    nueva = [o.id];
                  } else {
                    nueva = [
                      ...nueva.where((id) => _campo.opciones.every((x) => x.id != id || x.codigo != _campo.exclusiva)),
                      o.id,
                    ];
                  }
                } else {
                  nueva.remove(o.id);
                }
                widget.onChanged(nueva);
              },
            ),
        ],
      ),
    );
  }

  Widget _siNo(BuildContext context) {
    final actual = widget.valor is bool ? widget.valor as bool : null;
    return _marco(
      context,
      Wrap(
        key: Key('board-${_campo.clave}'),
        spacing: 12,
        children: [
          ChoiceChip(label: const Text('Sí'), selected: actual == true, onSelected: (_) => widget.onChanged(true)),
          ChoiceChip(label: const Text('No'), selected: actual == false, onSelected: (_) => widget.onChanged(false)),
        ],
      ),
    );
  }

  Widget _fecha(BuildContext context) {
    final fecha = widget.valor is String ? DateTime.tryParse(widget.valor as String) : null;
    final hoy = DateTime.now();
    return InkWell(
      key: Key('board-${_campo.clave}'),
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime(hoy.year - 45),
          firstDate: DateTime(1900),
          lastDate: hoy,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
        );
        if (elegida != null) widget.onChanged(DateFormat('yyyy-MM-dd').format(elegida));
      },
      child: InputDecorator(
        decoration: _decoracion().copyWith(
          suffixIcon: fecha != null && !_campo.obligatorio
              ? IconButton(
                  tooltip: 'Quitar la fecha',
                  icon: const Icon(Icons.close),
                  onPressed: () => widget.onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined),
        ),
        isEmpty: fecha == null,
        child: Text(fecha == null ? '' : DateFormat('d MMM yyyy', 'es').format(fecha)),
      ),
    );
  }

  Future<void> _elegirFoto(ImageSource origen) async {
    final archivo = await ImagePicker().pickImage(source: origen, maxWidth: 1600, imageQuality: 85);
    if (archivo == null || widget.subirFoto == null) return;
    setState(() => _subiendo = true);
    try {
      final ruta = await widget.subirFoto!(archivo.path);
      widget.onChanged(ruta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  void _menuFoto(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (hoja) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(hoja);
              _elegirFoto(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar una foto'),
            onTap: () {
              Navigator.pop(hoja);
              _elegirFoto(ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  Widget _foto(BuildContext context) {
    final ruta = widget.valor is String ? widget.valor as String : null;
    final nombre = ruta?.replaceFirst('/api/images/', '');
    return _marco(
      context,
      Row(
        key: Key('board-${_campo.clave}'),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _subiendo
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : nombre == null
                      ? ColoredBox(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.person_outline, size: 36),
                        )
                      : Image.network(
                          ApiConstants.imageUrl(nombre),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                        ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _subiendo ? null : () => _menuFoto(context),
              icon: const Icon(Icons.upload_outlined),
              label: Text(nombre == null ? 'Subir foto' : 'Cambiar foto'),
            ),
          ),
        ],
      ),
    );
  }
}

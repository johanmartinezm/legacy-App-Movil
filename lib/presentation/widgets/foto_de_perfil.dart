import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/config/image_helper.dart';
import '../../domain/providers/auth_provider.dart';

/// El círculo de la persona con sesión: su foto si la tiene, y si no, [sinFoto]
/// —el círculo que cada pantalla ya pintaba—.
///
/// Hasta el 2026-11-10 «Mi perfil», Inicio y la cabecera de las secciones
/// pintaban siempre un círculo vacío: la foto solo se veía dentro de editar
/// perfil. Si la imagen no carga, también se vuelve a [sinFoto].
class FotoDePerfil extends StatelessWidget {
  final double tamano;
  final Widget sinFoto;
  final Color colorDelBorde;
  final double anchoDelBorde;

  const FotoDePerfil({
    super.key,
    required this.tamano,
    required this.sinFoto,
    this.colorDelBorde = const Color(0xFF8AC6FB),
    this.anchoDelBorde = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    // Nulable a propósito: la cabecera de las secciones no dependía de
    // AuthProvider y hay pantallas (y pruebas) que la montan sin él. Sin
    // proveedor, el círculo de siempre en vez de una excepción.
    final foto = context.watch<AuthProvider?>()?.fotoPerfil;
    if (foto == null || foto.trim().isEmpty) return sinFoto;

    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorDelBorde, width: anchoDelBorde),
      ),
      child: ClipOval(
        child: Image.network(
          ImageHelper.resolverUrl(foto),
          // La clave es la URL: al cambiar la foto se pide la nueva.
          key: ValueKey(foto),
          fit: BoxFit.cover,
          width: tamano,
          height: tamano,
          errorBuilder: (_, __, ___) => sinFoto,
        ),
      ),
    );
  }
}

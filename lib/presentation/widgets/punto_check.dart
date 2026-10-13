import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un punto con check verde, título y texto. Lo usan la pantalla Legacy+ y la
/// sección Beneficios. Sin texto, solo el título: la pantalla Legacy+ recibe
/// los beneficios sin su detalle, que es para usuarios Legacy+.
class PuntoCheck extends StatelessWidget {
  final String titulo;
  final String texto;

  const PuntoCheck({super.key, required this.titulo, this.texto = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF0F2F20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check, color: Color(0xFF2ECC71), size: 14),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.barlow(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (texto.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: GoogleFonts.questrial(
                    fontSize: 13,
                    color: const Color(0xFF9FB2C2),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

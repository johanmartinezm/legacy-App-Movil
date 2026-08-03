import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_theme.dart';
import '../../widgets/custom_section_header.dart';
import '../../../data/services/synergy_service.dart';
import '../../../domain/providers/auth_provider.dart';

class SynergyCreateScreen extends StatefulWidget {
  const SynergyCreateScreen({super.key});

  @override
  State<SynergyCreateScreen> createState() => _SynergyCreateScreenState();
}

class _SynergyCreateScreenState extends State<SynergyCreateScreen> {
  final SynergyService _synergyService = SynergyService();
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  String _category = 'Negocios';
  bool _isLoading = false;

  final List<String> _categories = [
    'Negocios', 'Legal', 'Sucesión', 'Expansión', 'Inversiones', 'Personal'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await _synergyService.proposeSynergy(
        auth.token!, _title, _description, _category, null
      );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinergia propuesta con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(title: 'NUEVA SINERGIA', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Propon una idea o solicita ayuda a la red',
                        style: GoogleFonts.questrial(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'CATEGORÍA',
                        style: GoogleFonts.barlow(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.legacyGold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: _categories.map((c) => ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (val) => setState(() => _category = c),
                          selectedColor: AppTheme.legacyBlue1.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: _category == c ? AppTheme.legacyBlue1 : Colors.grey,
                            fontWeight: _category == c ? FontWeight.bold : FontWeight.normal,
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        decoration: _inputDecoration('Título de la Sinergia', 'Ej: Expansión en mercado europeo'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onSaved: (v) => _title = v!,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: _inputDecoration('Descripción detallada', 'Explica tu idea o necesidad...'),
                        maxLines: 8,
                        validator: (v) => v!.length < 20 ? 'Sé más descriptivo' : null,
                        onSaved: (v) => _description = v!,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.legacyBlue1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('PUBLICAR PROPUESTA', 
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppTheme.legacyBlue1, fontWeight: FontWeight.bold),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppTheme.legacyBlue1, width: 2),
      ),
    );
  }
}

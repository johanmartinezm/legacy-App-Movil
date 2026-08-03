import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../config/theme/app_theme.dart'; // updated
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;
  final Map<String, dynamic>? socialData;
  
  const RegisterScreen({super.key, this.role, this.socialData});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _identificationNumberController = TextEditingController();

  bool _isSocialLogin = false;

  @override
  void initState() {
    super.initState();
    if (widget.socialData != null) {
      _isSocialLogin = true;
      _emailController.text = widget.socialData!['email'] ?? '';
      
      final fullName = widget.socialData!['name'] ?? '';
      final parts = fullName.split(' ');
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  int _currentStep = 0;
  final GlobalKey<FormState> _personaFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _empresaFormKey = GlobalKey<FormState>();
  String? _selectedSector;
  String? _selectedGeneration;
  String _selectedCountry = 'Colombia';
  String? _selectedIdentificationType;
  String? _selectedCustomerStatus;
  String? _selectedPosition;
  final List<String> _selectedInterests = [];
  bool _acceptHabeasData = false;
  bool _acceptDataSharing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identificationNumberController.dispose();
    super.dispose();
  }

  void _onStepContinue() async {
    if (_currentStep == 0) {
      if (_personaFormKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else {
      if (_empresaFormKey.currentState!.validate()) {
        if (!_acceptHabeasData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes aceptar las políticas de privacidad y habeas data'),
            ),
          );
          return;
        }

        // Call AuthProvider to register
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final provider = widget.socialData?['provider'];
        final idToken = widget.socialData?['id_token'] as String?;
        
        final success = await authProvider.register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _isSocialLogin ? null : _passwordController.text,
          googleId: provider == 'google' ? idToken : null,
          appleId: provider == 'apple' ? idToken : null,
          companyName: _companyController.text,
          jobTitle: _selectedPosition,
          country: _selectedCountry,
          identificationType: _selectedIdentificationType,
          identificationNumber: _identificationNumberController.text,
          customerStatus: _selectedCustomerStatus,
          birthDate: _birthDateController.text,
          generation: _selectedGeneration,
          industry: _selectedSector,
          interests: _selectedInterests,
          role: widget.role,
          termsAccepted: _acceptHabeasData,
          dataSharingAccepted: _acceptDataSharing,
        );

        if (success) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Cuenta Creada'),
                content: const Text(
                  'Tu cuenta ha sido creada exitosamente. Por favor, revisa tu bandeja de entrada o carpeta de SPAM y confirma tu correo electrónico antes de iniciar sesión.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/login');
                    },
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Error al registrar',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        centerTitle: true,
        backgroundColor: AppTheme.legacyBlue2,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'INFORMACIÓN DE REGISTRO\n\nEsta información es muy importante para dar contenido de valor.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Stepper(
                type: StepperType.vertical,
                // physics: const ClampingScrollPhysics(), // Let Stepper handle physics naturally
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                // Hide Stepper's internal controls; we render persistent controls below the form
                controlsBuilder: (context, details) => const SizedBox.shrink(),

                steps: [
                  Step(
                    title: const Text('Persona'),
                    isActive: _currentStep == 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: Form(
                      key: _personaFormKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Nombre',
                            hint: 'Juan',
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Apellido',
                            hint: 'Pérez',
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu apellido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Correo',
                            hint: 'tu@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: _isSocialLogin,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa un correo';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Teléfono',
                            hint: '+57 300 123 4567',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu teléfono';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Fecha de nacimiento (date picker)
                          Text(
                            'Fecha de nacimiento',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'DD/MM/AAAA',
                            ),
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(1990),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                _birthDateController.text =
                                    '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                              }
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Empresa'),
                    isActive: _currentStep == 1,
                    state: _currentStep == 1
                        ? StepState.editing
                        : StepState.indexed,
                    content: Form(
                      key: _empresaFormKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedCountry,
                            decoration: const InputDecoration(
                              labelText: 'País',
                            ),
                            items: ['Colombia', 'Otro']
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCountry = val!;
                                _selectedIdentificationType = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedCountry),
                            isExpanded: true,
                            initialValue: _selectedIdentificationType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Identificación',
                            ),
                            items:
                                (_selectedCountry == 'Colombia'
                                        ? ['Cédula', 'Cédula de extranjería', 'NIT', 'Pasaporte', 'Tarjeta de identidad']
                                        : [
                                            'Pasaporte',
                                            'Documento extranjero',
                                            'Otro',
                                          ])
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) => setState(
                              () => _selectedIdentificationType = val,
                            ),
                            validator: (val) =>
                                val == null ? 'Selecciona un tipo' : null,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Número de Identificación',
                            hint: '1234567890',
                            controller: _identificationNumberController,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Ingresa el número de identificación';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedPosition,
                            decoration: const InputDecoration(
                              labelText: 'Rol del solicitante',
                            ),
                            items: [
                              'Fundador', 'Propietario', 'Miembro de junta directiva',
                              'Presidente', 'Vicepresidente', 'CEO/Gerente general',
                              'Socio', 'Director ejecutivo', 'Gerente', 'Director',
                              'Jefe/líder de área', 'Consultor', 'Asesor',
                              'Consejero o miembro consultivo', 'Otro'
                            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _selectedPosition = val),
                            validator: (value) => value == null || value.isEmpty ? 'Selecciona tu rol' : null,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Empresa',
                            hint: 'Mi Empresa S.A.',
                            controller: _companyController,
                            validator: (val) => val == null || val.isEmpty ? 'Ingresa el nombre de la empresa' : null,
                          ),
                          const SizedBox(height: 16),

                          // Customer Status Dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedCustomerStatus,
                            decoration: const InputDecoration(
                              labelText: 'Estado de Cliente/Alumni',
                            ),
                            items: [
                              'Legacy School of Ownership',
                              'Legacy & Management',
                              'Legacy Legal',
                              'Aurum Legacy Advisors',
                              'Legacy Summit',
                              'No soy cliente',
                            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _selectedCustomerStatus = val),
                            validator: (value) => value == null || value.isEmpty ? 'Selecciona tu estado' : null,
                          ),
                          const SizedBox(height: 16),

                          // Interests Multi-select
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intereses',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                children: ['Gobierno corporativo', 'Familia empresaria'].map((interest) {
                                  return FilterChip(
                                    label: Text(interest),
                                    selected: _selectedInterests.contains(interest),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedInterests.add(interest);
                                        } else {
                                          _selectedInterests.remove(interest);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Generation Dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedGeneration,
                            decoration: const InputDecoration(
                              labelText: 'Generación',
                            ),
                            items:
                                [
                                      'Primera (Fundador)',
                                      'Segunda',
                                      'Tercera',
                                      'Cuarta',
                                      'Quinta o más',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGeneration = val),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona tu generación';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedSector,
                            decoration: const InputDecoration(
                              labelText: 'Sector',
                            ),
                            items:
                                [
                                      'Servicios',
                                      'Comercio',
                                      'Manufactura e Industria',
                                      'Agropecuario',
                                      'Construcción y Energía',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSector = val),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona un sector';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          CustomTextField(
                            label: 'Contrasena',
                            hint: '********',
                            controller: _passwordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Minimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Confirmar Contrasena',
                            hint: '********',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Las contrasenas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Terms Checkboxes
                          CheckboxListTile(
                            value: _acceptHabeasData,
                            onChanged: (value) => setState(() => _acceptHabeasData = value ?? false),
                            title: const Text('Certifico y confirmo a Legacy Network que cumplo con las políticas de mi empleador y las leyes aplicables para registrarme y usar esta aplicación. Acepto el uso de mi información personal de acuerdo con la política de privacidad y habeas data vigente.', style: TextStyle(fontSize: 12)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            value: _acceptDataSharing,
                            onChanged: (value) => setState(() => _acceptDataSharing = value ?? false),
                            title: const Text('Legacy Network se toma muy en serio la privacidad de sus datos. Marque esta casilla para permitirnos compartir su información de contacto con las unidades de Legacy Network (incluyendo Certifico), con el objetivo de mantenerlo informado sobre programas, servicios y novedades.', style: TextStyle(fontSize: 12)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(
                            height: 80,
                          ), // Extra space for persistent bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Persistent controls to improve reachability (fixed at bottom)
      // AnimatedPadding moves the bar up by the keyboard inset when present
      bottomNavigationBar: AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _onStepCancel,
                    child: const Text('Atrás'),
                  ),
                const SizedBox(width: 8),

                // Terms area (visible on the Empresa step)
                if (_currentStep == 1)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _acceptHabeasData = !_acceptHabeasData),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _acceptHabeasData,
                            onChanged: (value) => setState(() => _acceptHabeasData = value ?? false),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Expanded(
                            child: Text(
                              'Acepto Política de Privacidad y Habeas Data',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),

                // Primary action
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.legacyBlue2,
                      elevation: 6,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      minimumSize: const Size(120, 44),
                    ),
                    child: Text(
                      _currentStep == 1 ? 'Crear Cuenta' : 'Siguiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

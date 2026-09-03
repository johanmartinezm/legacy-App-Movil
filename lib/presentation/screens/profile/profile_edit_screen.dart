import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';
import '../../widgets/boton_volver.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // ... controllers and state ...
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final TextEditingController _aliasController = TextEditingController();

  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();

  // Sexo, departamento y direccion llegaron con la carga masiva del Summit
  // (reports/20260826_plan_carga_masiva.md 3.1). Solo se ven aqui, dentro de
  // editar perfil: ni en ver perfil ni en ninguna lista.
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  String _selectedGeneration = 'Segunda';
  String _selectedSector = 'Tecnología';

  /// Lo que se muestra cuando la cuenta no tiene sexo registrado. Al guardar
  /// viaja como cadena vacia, no con este texto.
  static const String _sexoSinEspecificar = 'Sin especificar';
  static const List<String> _opcionesDeSexo = [
    _sexoSinEspecificar,
    'Femenino',
    'Masculino',
    'Otro',
  ];
  String _selectedSexo = _sexoSinEspecificar;
  String _photoUrl = '';

  bool _isEditing = false;
  bool _isLoading = true;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final authService = AuthService();
      final data = await authService.getProfile(authProvider.token!);

      setState(() {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _locationController.text = data['location'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _aliasController.text = data['alias'] ?? '';
        _companyController.text = data['company_name'] ?? '';
        _jobTitleController.text = data['job_title'] ?? '';
        // Handle dropdowns or defaults
        _selectedGeneration = data['generation'] ?? 'Segunda';
        _departamentoController.text = data['departamento'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        // Un valor que no este en la lista reventaria el desplegable, y el
        // importador puede traer cualquier cosa escrita a mano.
        final sexo = (data['sexo'] ?? '').toString();
        _selectedSexo = _opcionesDeSexo.contains(sexo) && sexo.isNotEmpty
            ? sexo
            : _sexoSinEspecificar;
        _photoUrl = data['profile_image_url'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar perfil: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _aliasController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _departamentoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar imagen')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.legacyBlue2,
                ),
                title: Text('Galería', style: GoogleFonts.questrial()),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: AppTheme.legacyBlue2,
                ),
                title: Text('Cámara', style: GoogleFonts.questrial()),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final body = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
        'bio': _bioController.text,
        'alias': _aliasController.text,
        'company_name': _companyController.text,
        'job_title': _jobTitleController.text,
        'generation': _selectedGeneration,
        'sector': _selectedSector,
        // Las tres claves coinciden con las etiquetas json del backend
        // (domain/user.go). Comprobado: 'sector' de la linea de arriba NO
        // coincide con ninguna —el campo es 'industry'— y por eso ese
        // desplegable no guarda nada; arreglarlo es aparte.
        'sexo': _selectedSexo == _sexoSinEspecificar ? '' : _selectedSexo,
        'departamento': _departamentoController.text,
        'direccion': _direccionController.text,
      };

      await authService.updateProfile(authProvider.token!, body);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppTheme.legacyGreenDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      String message = 'Error al actualizar perfil';
      if (e.toString().contains('alias_in_use')) {
        message = 'El alias ya está en uso. Por favor elige otro.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BotonVolver(),
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.legacyBlue1,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar Perfil',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Guardar',
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER - Personal Identity
                  Container(
                    width: double.infinity,
                    color: AppTheme.legacyBlue1,
                    padding: const EdgeInsets.only(bottom: 32, top: 16),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : (_photoUrl.isNotEmpty
                                          ? NetworkImage(
                                              ImageHelper.getProxiedImageUrl(
                                                  _photoUrl))
                                          : null),
                                child: (_imageFile == null && _photoUrl.isEmpty)
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                            ),
                            if (_isEditing)
                              GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.legacyBlue2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_firstNameController.text} ${_lastNameController.text}',
                          style: GoogleFonts.barlow(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_jobTitleController.text} @ ${_companyController.text}',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            color: AppTheme.legacyBlue4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FORM CONTENT
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Personal Info
                        _buildSectionTitle('Información Personal'),
                        const SizedBox(height: 16),

                        _buildTextField(
                          'Nombre',
                          _firstNameController,
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Apellido',
                          _lastNameController,
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Email',
                          _emailController,
                          Icons.email_outlined,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Teléfono',
                          _phoneController,
                          Icons.phone_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Ubicación',
                          _locationController,
                          Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          'Sexo',
                          _selectedSexo,
                          _opcionesDeSexo,
                          Icons.wc_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Departamento',
                          _departamentoController,
                          Icons.map_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Dirección',
                          _direccionController,
                          Icons.home_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Bio',
                          _bioController,
                          Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Alias (Para Foros Anónimos)',
                          _aliasController,
                          Icons.visibility_off_outlined,
                        ),

                        const SizedBox(height: 32),

                        // Section 2: Legacy Profile
                        _buildSectionTitle('Perfil Empresarial'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.legacyBlue5.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.legacyBlue5.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                'Empresa Familiar',
                                _companyController,
                                Icons.business,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Cargo',
                                _jobTitleController,
                                Icons.work_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                'Generación',
                                _selectedGeneration,
                                [
                                  'Primera (Fundador)',
                                  'Segunda',
                                  'Tercera',
                                  'Cuarta',
                                  'Quinta o más',
                                ],
                                Icons.groups_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown('Sector', _selectedSector, [
                                'Agroindustria',
                                'Comercio',
                                'Construcción',
                                'Finanzas',
                                'Manufactura',
                                'Servicios',
                                'Tecnología',
                                'Otro',
                              ], Icons.category_outlined),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Section 3: Security
                        _buildSectionTitle('Seguridad'),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.legacyBlue5.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              color: AppTheme.legacyBlue2,
                            ),
                          ),
                          title: Text(
                            'Cambiar Contraseña',
                            style: GoogleFonts.questrial(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Actualiza tu clave de acceso',
                            style: GoogleFonts.questrial(fontSize: 14),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: _showChangePasswordDialog,
                        ),

                        const SizedBox(height: 32),

                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: GestureDetector(
                              onTap: _saveProfile,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.legacyBlue1,
                                      AppTheme.legacyBlue2,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.legacyBlue1.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'GUARDAR CAMBIOS',
                                    style: GoogleFonts.barlow(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
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

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool isOldVisible = false;
    bool isNewVisible = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: AppTheme.legacyBlue1.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.legacyBlue5.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppTheme.legacyBlue1,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cambiar Contraseña',
                          style: GoogleFonts.barlow(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.legacyBlue1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Asegura tu cuenta con una clave robusta',
                          style: GoogleFonts.questrial(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        _buildDialogField(
                          'Contraseña Actual',
                          oldPasswordController,
                          Icons.lock_open,
                          isOldVisible,
                          () => setDialogState(
                            () => isOldVisible = !isOldVisible,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDialogField(
                          'Nueva Contraseña',
                          newPasswordController,
                          Icons.lock_person_outlined,
                          isNewVisible,
                          () => setDialogState(
                            () => isNewVisible = !isNewVisible,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDialogField(
                          'Confirmar Contraseña',
                          confirmPasswordController,
                          Icons.verified_user_outlined,
                          isNewVisible,
                          () => setDialogState(
                            () => isNewVisible = !isNewVisible,
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'CANCELAR',
                                  style: GoogleFonts.barlow(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () async {
                                        if (newPasswordController.text !=
                                            confirmPasswordController.text) {
                                          _showError(
                                            context,
                                            'Las contraseñas no coinciden',
                                          );
                                          return;
                                        }

                                        setDialogState(() => isLoading = true);

                                        try {
                                          final authProvider =
                                              Provider.of<AuthProvider>(
                                                context,
                                                listen: false,
                                              );
                                          final authService = AuthService();
                                          await authService.changePassword(
                                            authProvider.token!,
                                            oldPasswordController.text,
                                            newPasswordController.text,
                                          );

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Contraseña actualizada',
                                                ),
                                                backgroundColor:
                                                    AppTheme.legacyGreenDark,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            setDialogState(
                                              () => isLoading = false,
                                            );
                                            _showError(context, e.toString());
                                          }
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.legacyBlue1,
                                        AppTheme.legacyBlue2,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.legacyBlue1.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'ACTUALIZAR',
                                            style: GoogleFonts.barlow(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isVisible,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            color: AppTheme.legacyBlue2,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          style: GoogleFonts.questrial(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.legacyBlue3, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
                size: 18,
              ),
              onPressed: onToggle,
            ),
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey[300]),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.legacyBlue3,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.barlow(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.legacyBlue1,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.w600,
            color: AppTheme.legacyBlue2,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly || !_isEditing,
          maxLines: maxLines,
          style: GoogleFonts.questrial(
            color: readOnly ? Colors.grey[600] : Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.legacyBlue3, size: 20),
            filled: _isEditing && !readOnly,
            fillColor: _isEditing ? Colors.grey[50] : Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: _isEditing && !readOnly
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.legacyBlue5),
                  )
                : InputBorder.none,
            enabledBorder: _isEditing && !readOnly
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.legacyBlue5),
                  )
                : InputBorder.none,
            focusedBorder: _isEditing && !readOnly
                ? const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      color: AppTheme.legacyBlue2,
                      width: 1.5,
                    ),
                  )
                : InputBorder.none,
          ),
        ),
        if (!_isEditing) const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String currentValue,
    List<String> items,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.w600,
            color: AppTheme.legacyBlue2,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        _isEditing
            ? DropdownButtonFormField<String>(
                initialValue: currentValue,
                icon: const Icon(Icons.arrow_drop_down),
                style: GoogleFonts.questrial(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: AppTheme.legacyBlue3, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.legacyBlue5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.legacyBlue5),
                  ),
                ),
                items: items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    if (label == 'Generación') _selectedGeneration = newValue!;
                    if (label == 'Sector') _selectedSector = newValue!;
                    if (label == 'Sexo') _selectedSexo = newValue!;
                  });
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.legacyBlue3, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      currentValue,
                      style: GoogleFonts.questrial(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
        if (!_isEditing) const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

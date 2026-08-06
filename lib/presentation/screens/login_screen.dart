import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/banner_provider.dart';
import '../../config/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isPreparingContent = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savedEmail = await authProvider.getSavedEmail();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // "Recordarme" también aplica a Google y Apple: la casilla está en el mismo
    // formulario y el usuario no tiene por qué saber que solo valía para el
    // acceso con correo.
    final result = await authProvider.handleSocialLogin(
      provider,
      rememberMe: _rememberMe,
    );

    if (result == null) return; // Error or canceled

    if (!context.mounted) return;

    if (result['action'] == 'register') {
      // Navigate to register and pass pre-filled parameters
      context.push(
        '/register', 
        extra: {
          'email': result['email'],
          'name': result['name'],
          'provider': result['provider'],
          'id_token': result['id_token'],
        },
      );
    } else if (result['action'] == 'login') {
      setState(() => _isPreparingContent = true);
      await context.read<BannerProvider>().precacheAllBanners(context);
      if (context.mounted) context.go('/home');
    }
  }

  void _showSecurityDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/intelyclick_security.png',
              height: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Ciberseguridad Avanzada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.legacyBlue4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Colors.white70,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Su seguridad es nuestra prioridad. En Intelyclick Security, seguimos los protocolos más estrictos de seguridad, encriptando la información más sensible. Aplicamos las mejores prácticas de la industria y realizamos el monitoreo constante de amenazas mediante nuestro SOC con IA (Security Operations Center) de nivel global. ',
                  ),
                  TextSpan(
                    text: 'https://intelyclick.com/soc-intel-y-click.html',
                    style: const TextStyle(
                      color: AppTheme.legacyBlue5,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url = Uri.parse(
                          'https://intelyclick.com/soc-intel-y-click.html',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.legacyBlue3,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entendido'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gradient matching the deep navy background of the reference image
    final bgGradient = RadialGradient(
      colors: const [Color(0xFF13304A), Color(0xFF071324), Color(0xFF050B15)],
      center: const Alignment(0.8, -0.6),
      radius: 1.5,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Centered White Network/Logo from assets/images/logo_dark.png
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/Logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Brand Header
                    Text(
                      'Legacy Network',
                      style: GoogleFonts.barlow(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El futuro de su legado se construye hoy',
                      style: GoogleFonts.questrial(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // --- Form Fields ---
                    Text(
                      'Email',
                      style: GoogleFonts.questrial(
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu email';
                        }
                        if (!value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'nombre@empresa.com',
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Contraseña',
                      style: GoogleFonts.questrial(
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white38,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Remember Me & Forgot Password Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Un solo punto que alterna el estado. Antes había un
                        // GestureDetector envolviendo al Checkbox y ambos
                        // cambiaban `_rememberMe`, de modo que el
                        // comportamiento dependía de si el dedo caía sobre la
                        // casilla o sobre el texto.
                        InkWell(
                          key: const Key('login-recordarme'),
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: IgnorePointer(
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (_) {},
                                      // Sin colores explícitos, la casilla
                                      // quedaba casi invisible sobre el fondo
                                      // oscuro de esta pantalla.
                                      side: const BorderSide(
                                        color: Colors.white70,
                                        width: 1.5,
                                      ),
                                      activeColor: const Color(0xFFD9A74A),
                                      checkColor: const Color(0xFF050B15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recordarme',
                                  style: GoogleFonts.questrial(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '¿Olvidó su contraseña?',
                            style: GoogleFonts.questrial(
                              color: AppTheme.legacyBlue4,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- Login Button ---
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Column(
                          children: [
                            if (authProvider.errorMessage != null && authProvider.errorMessage != 'email_not_verified')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authProvider.errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1F5E80),
                                    Color(0xFF123A4F),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    (authProvider.isLoading ||
                                        _isPreparingContent)
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          final success = await authProvider
                                              .login(
                                                _emailController.text,
                                                _passwordController.text,
                                                rememberMe: _rememberMe,
                                              );

                                          if (success && context.mounted) {
                                            setState(
                                              () => _isPreparingContent = true,
                                            );

                                            // Preload banners
                                            await context
                                                .read<BannerProvider>()
                                                .precacheAllBanners(context);

                                            if (context.mounted) {
                                              context.go('/home');
                                            }
                                          } else if (!success && context.mounted) {
                                            if (authProvider.errorMessage == 'email_not_verified') {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Correo no verificado'),
                                                  content: const Text('Para iniciar sesión, primero debes verificar tu cuenta. ¿Deseas que te reenviemos el correo de verificación?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        Navigator.pop(context);
                                                        final resent = await authProvider.resendVerificationEmail(_emailController.text);
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(resent ? 'Correo reenviado exitosamente' : 'Error al reenviar el correo'),
                                                              backgroundColor: resent ? Colors.green : Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: const Text('Reenviar correo'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    (authProvider.isLoading ||
                                        _isPreparingContent)
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Iniciar sesión',
                                        style: GoogleFonts.barlow(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 20),

                    // --- Google / Apple login buttons layout ---
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: InkWell(
                              onTap: () => _handleSocialLogin('google'),
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'Google',
                                  style: GoogleFonts.barlow(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: InkWell(
                              onTap: () => _handleSocialLogin('apple'),
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'Apple',
                                  style: GoogleFonts.barlow(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- Footer Register ---
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '¿No tiene cuenta? ',
                          style: GoogleFonts.questrial(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/legal-notice'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Regístrese gratis',
                            style: GoogleFonts.questrial(
                              color: AppTheme.legacyBlue4,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Security Sello (Intelyclick) ---
                    Center(
                      child: InkWell(
                        onTap: () => _showSecurityDetails(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Intelyclick Security',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: AppTheme.legacyBlue4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'PROTECCIÓN INTELIGENTE DE DATOS',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

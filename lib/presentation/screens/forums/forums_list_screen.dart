import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/forum_provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/models/forum_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../data/services/auth_service.dart';

class ForumsListScreen extends StatefulWidget {
  const ForumsListScreen({Key? key}) : super(key: key);

  @override
  State<ForumsListScreen> createState() => _ForumsListScreenState();
}

class _ForumsListScreenState extends State<ForumsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ForumProvider>(context, listen: false).loadForums();
      _checkAlias();
    });
  }

  Future<void> _checkAlias() async {
    final auth = context.read<AuthProvider>();
    if (auth.alias == null || auth.alias!.isEmpty) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _AliasDialog(),
      );
      // Reload forums when dialog closes as the user might be ready
      if (mounted) {
        Provider.of<ForumProvider>(context, listen: false).loadForums();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      appBar: AppBar(
        title: const Text('Foros Anónimos'),
        backgroundColor: AppTheme.legacyBlue2,
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.forums.isEmpty) {
            return const Center(
              child: Text(
                'No hay foros activos en este momento.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadForums(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.forums.length,
              itemBuilder: (context, index) {
                final forum = provider.forums[index];
                return _ForumCard(forum: forum);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.legacyBlue4,
        child: const Icon(Icons.add),
        onPressed: () {
          context.push('/forum-propose');
        },
      ),
    );
  }
}

class _ForumCard extends StatelessWidget {
  final Forum forum;

  const _ForumCard({required this.forum});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF162534),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/forum-thread', extra: forum);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      forum.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (forum.status == 'locked')
                    const Tooltip(
                      message: 'Foro de Solo Lectura',
                      child: Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                forum.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Por: ${forum.authorAlias.isNotEmpty ? forum.authorAlias : 'Administración'}',
                    style: const TextStyle(
                      color: AppTheme.legacyBlue4,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        '${forum.postCount}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AliasDialog extends StatefulWidget {
  const _AliasDialog();

  @override
  State<_AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<_AliasDialog> {
  final TextEditingController _aliasController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _saveAlias() async {
    final alias = _aliasController.text.trim();
    if (alias.isEmpty) {
      setState(() => _errorMessage = 'El alias no puede estar vacío');
      return;
    }

    final auth = context.read<AuthProvider>();
    final authService = AuthService();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authService.updateProfile(auth.token!, {'alias': alias});
      
      // Update local profile state
      await auth.fetchProfile();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('alias_in_use')) {
          _errorMessage = 'El alias ya está en uso. Por favor elige otro.';
        } else {
          _errorMessage = 'Error al guardar el alias.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF162534),
      title: const Text('¡Bienvenido a los Foros!', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Para participar en los debates confidenciales de manera anónima, necesitas configurar un Alias único.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aliasController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Escribe tu alias aquí...',
              hintStyle: const TextStyle(color: Colors.white38),
              errorText: _errorMessage,
              filled: true,
              fillColor: AppTheme.legacyBlue1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircularProgressIndicator(),
          )
        else
          TextButton(
            onPressed: _saveAlias,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.legacyBlue4,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar y Entrar'),
          ),
      ],
    );
  }
}

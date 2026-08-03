import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../../config/theme/app_theme.dart';
import '../../widgets/custom_section_header.dart';
import '../../../data/services/synergy_service.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/models/synergy_model.dart';
import '../../../data/config/image_helper.dart';

class SynergyDetailScreen extends StatefulWidget {
  final Synergy synergy;
  const SynergyDetailScreen({super.key, required this.synergy});

  @override
  State<SynergyDetailScreen> createState() => _SynergyDetailScreenState();
}

class _SynergyDetailScreenState extends State<SynergyDetailScreen> {
  final SynergyService _synergyService = SynergyService();
  final TextEditingController _commentController = TextEditingController();
  late Synergy _currentSynergy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSynergy = widget.synergy;
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    final auth = context.read<AuthProvider>();
    final detailed = await _synergyService.getSynergyById(_currentSynergy.id, auth.token);
    if (detailed != null) {
      setState(() {
        _currentSynergy = detailed;
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await _synergyService.commentSynergy(auth.token!, _currentSynergy.id, _commentController.text);
      _commentController.clear();
      await _loadFullDetails();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    try {
      await _synergyService.toggleLike(auth.token!, _currentSynergy.id);
      await _loadFullDetails();
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(title: 'DETALLE DE SINERGIA', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAuthorHeader(),
                    const SizedBox(height: 20),
                    Text(
                      _currentSynergy.title,
                      style: GoogleFonts.barlow(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.legacyBlue1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _currentSynergy.description,
                      style: GoogleFonts.questrial(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                    const Divider(height: 40),
                    _buildStatsRow(),
                    const Divider(height: 40),
                    Text(
                      'OPINIONES DE LA RED',
                      style: GoogleFonts.barlow(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.legacyGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCommentsList(),
                  ],
                ),
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.legacyGold.withValues(alpha: 0.1),
          backgroundImage: _currentSynergy.author?.profileImageUrl != null
              ? NetworkImage(ImageHelper.getProxiedImageUrl(
                  _currentSynergy.author!.profileImageUrl!))
              : null,
          child: _currentSynergy.author?.profileImageUrl == null
              ? const Icon(Icons.person, color: AppTheme.legacyGold)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentSynergy.author?.fullName ?? 'Miembro Legacy',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_currentSynergy.category} • ${intl.DateFormat('dd/MM/yyyy HH:mm').format(_currentSynergy.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatIcon(icon: Icons.remove_red_eye_outlined, label: '${_currentSynergy.viewsCount} vistas'),
        const SizedBox(width: 20),
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _StatIcon(
              icon: Icons.favorite_border, // We could change to solid if we track personal like state
              label: '${_currentSynergy.likesCount} interesados',
              color: AppTheme.legacyGold,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _StatIcon(icon: Icons.chat_bubble_outline, label: '${_currentSynergy.commentsCount} opiniones'),
        const Spacer(),
        IconButton(
          onPressed: () {}, // Share functionality
          icon: const Icon(Icons.share_outlined, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    final comments = _currentSynergy.comments ?? [];
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No hay opiniones aún. ¡Sé el primero!', 
            style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: comment.isExpertFeedback ? AppTheme.legacyGold.withValues(alpha: 0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: comment.isExpertFeedback ? Border.all(color: AppTheme.legacyGold.withValues(alpha: 0.3)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.user?.fullName ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (comment.isExpertFeedback) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, size: 14, color: AppTheme.legacyGold),
                    const Text(' MENTOR', style: TextStyle(fontSize: 10, color: AppTheme.legacyGold, fontWeight: FontWeight.bold)),
                  ],
                  const Spacer(),
                  Text(
                    intl.DateFormat('dd/MM HH:mm').format(comment.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.content,
                style: GoogleFonts.questrial(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Escribe tu opinión o consejo...',
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _isLoading 
            ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2))
            : CircleAvatar(
                backgroundColor: AppTheme.legacyBlue1,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _postComment,
                ),
              ),
        ],
      ),
    );
  }
}

class _StatIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatIcon({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color ?? Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}

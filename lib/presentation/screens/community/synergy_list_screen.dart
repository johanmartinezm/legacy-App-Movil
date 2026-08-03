import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../../../config/theme/app_theme.dart';
import '../../widgets/custom_section_header.dart';
import '../../../data/services/synergy_service.dart';
import '../../../domain/models/synergy_model.dart';
import '../../../data/config/image_helper.dart';

class SynergyListScreen extends StatefulWidget {
  const SynergyListScreen({super.key});

  @override
  State<SynergyListScreen> createState() => _SynergyListScreenState();
}

class _SynergyListScreenState extends State<SynergyListScreen> {
  final SynergyService _synergyService = SynergyService();
  final TextEditingController _searchController = TextEditingController();
  List<Synergy> _synergies = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Todas';

  final List<String> _categories = [
    'Todas', 'Negocios', 'Legal', 'Sucesión', 'Expansión', 'Inversiones', 'Personal'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSynergies();
  }

  Future<void> _fetchSynergies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final synergies = await _synergyService.getSynergies(
        category: _selectedCategory,
        search: _searchController.text,
      );
      setState(() {
        _synergies = synergies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar el foro comunitario';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/comite-sinergias/crear'),
        backgroundColor: AppTheme.legacyBlue1,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(
              title: 'COMITÉ DE SINERGIAS',
              showBackButton: true,
            ),
            _buildSearchAndFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.legacyBlue1,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSynergies,
                      child: _synergies.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _synergies.length,
                              itemBuilder: (context, index) {
                                return _SynergyCard(synergy: _synergies[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _fetchSynergies(),
              decoration: InputDecoration(
                hintText: 'Buscar propuestas...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.legacyBlue1),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                    _fetchSynergies();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.legacyBlue1,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: isSelected ? AppTheme.legacyBlue1 : Colors.grey[200]!),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Aún no hay propuestas',
              style: GoogleFonts.barlow(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.legacyBlue1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sé el primero en proponer una sinergia para la comunidad Legacy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.questrial(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SynergyCard extends StatelessWidget {
  final Synergy synergy;

  const _SynergyCard({required this.synergy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/comite-sinergias/detalle', extra: synergy),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.legacyGold.withValues(alpha: 0.2),
                        backgroundImage: synergy.author?.profileImageUrl != null
                            ? NetworkImage(ImageHelper.getProxiedImageUrl(
                                synergy.author!.profileImageUrl!))
                            : null,
                        child: synergy.author?.profileImageUrl == null
                            ? const Icon(Icons.person, size: 20, color: AppTheme.legacyGold)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              synergy.author?.fullName ?? 'Miembro Legacy',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Propuesta en ${synergy.category} • ${intl.DateFormat('dd/MM/yyyy HH:mm').format(synergy.createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: synergy.status == 'active' 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          synergy.status == 'active' ? 'Abierta' : 'Cerrada',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: synergy.status == 'active' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    synergy.title,
                    style: GoogleFonts.barlow(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.legacyBlue1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    synergy.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _IconStat(icon: Icons.remove_red_eye_outlined, count: synergy.viewsCount),
                      const SizedBox(width: 16),
                      _IconStat(icon: Icons.favorite_border, count: synergy.likesCount),
                      const SizedBox(width: 16),
                      _IconStat(icon: Icons.chat_bubble_outline, count: synergy.commentsCount),
                      const Spacer(),
                      const Text(
                        'Ver detalles',
                        style: TextStyle(
                          color: AppTheme.legacyGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.legacyGold),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  final IconData icon;
  final int count;

  const _IconStat({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

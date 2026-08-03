import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../domain/providers/forum_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/models/forum_model.dart';
import '../../../data/config/api_constants.dart';

class ForumThreadScreen extends StatefulWidget {
  final Forum forum;

  const ForumThreadScreen({Key? key, required this.forum}) : super(key: key);

  @override
  State<ForumThreadScreen> createState() => _ForumThreadScreenState();
}

class _ForumThreadScreenState extends State<ForumThreadScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ForumPost> _posts = [];
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await Provider.of<ForumProvider>(context, listen: false)
          .loadPosts(widget.forum.id);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando posts: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 300,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiConstants.baseUrl}/images/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);
        return data['name'];
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }

  void _sendPost() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        final uploaded = await _uploadImage(_selectedImage!);
        if (uploaded != null) imageUrl = uploaded;
      }

      final newPost = await Provider.of<ForumProvider>(context, listen: false)
          .publishPost(widget.forum.id, text, imageUrl);

      if (mounted) {
        setState(() {
          _posts.add(newPost);
          _textController.clear();
          _selectedImage = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      String message = 'Error al publicar.';
      if (e.toString().contains('alias_required')) {
        message = 'Debes configurar un Alias en tu perfil para publicar de forma anónima.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _reportPost(String postId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          backgroundColor: AppTheme.legacyBlue1,
          title: const Text('Reportar Publicación', style: TextStyle(color: Colors.white)),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '¿Por qué reportas esta publicación?',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            onChanged: (val) => input = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, input),
              child: const Text('Reportar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.trim().isNotEmpty) {
      try {
        await Provider.of<ForumProvider>(context, listen: false)
            .reportPost(postId, reason.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación reportada correctamente.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al reportar.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      appBar: AppBar(
        title: Text(widget.forum.title),
        backgroundColor: AppTheme.legacyBlue2,
      ),
      body: Column(
        children: [
          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return _PostBubble(
                        post: post,
                        onReport: () => _reportPost(post.id),
                      );
                    },
                  ),
          ),
          // Input Area
          if (widget.forum.status == 'locked')
            Container(
              color: Colors.orange.shade50.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Foro de Solo Lectura',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            Container(
              color: const Color(0xFF162534),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SafeArea(
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.white54),
                          onPressed: _isSending ? null : _pickImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje anónimo...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                          ),
                        ),
                        if (_isSending)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.send, color: AppTheme.legacyBlue4),
                            onPressed: _sendPost,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostBubble extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onReport;

  const _PostBubble({required this.post, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            child: Text(
              post.authorAlias.isNotEmpty ? post.authorAlias[0].toUpperCase() : 'A',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.authorAlias.isNotEmpty ? post.authorAlias : 'Anónimo',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                      color: AppTheme.legacyBlue1,
                      onSelected: (val) {
                        if (val == 'report') onReport();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Reportar (Ofensivo/Spam)', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162534),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.content.isNotEmpty)
                        Text(
                          post.content,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      if (post.imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              '${ApiConstants.baseUrl}/images/${post.imageUrl}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

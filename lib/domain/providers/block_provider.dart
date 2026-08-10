import 'package:flutter/foundation.dart';
import '../../data/models/blocked_user_model.dart';
import '../../data/services/block_service.dart';

/// Estado de bloqueos y reportes.
///
/// Mantiene además el conjunto de ids bloqueados, para que las pantallas puedan
/// ocultar de inmediato a quien se acaba de bloquear sin esperar a que el
/// servidor vuelva a responder la lista.
class BlockProvider with ChangeNotifier {
  BlockService? _service;

  List<BlockedUser> _blocked = [];
  final Set<String> _blockedIds = {};
  bool _loading = false;
  String? _error;

  List<BlockedUser> get blocked => _blocked;
  bool get loading => _loading;
  String? get error => _error;

  bool isBlocked(String userId) => _blockedIds.contains(userId);

  /// Se llama desde el ProxyProvider cuando cambia la sesión.
  void updateToken(String? token) {
    if (token == null || token.isEmpty) {
      _service = null;
      _blocked = [];
      _blockedIds.clear();
      return;
    }
    _service = BlockService(token);
  }

  Future<void> loadBlocked() async {
    if (_service == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _blocked = await _service!.listBlocked();
      _blockedIds
        ..clear()
        ..addAll(_blocked.map((b) => b.userId));
    } catch (e) {
      _error = _limpiar(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Devuelve true si el bloqueo se hizo. La pantalla decide qué mostrar; aquí
  /// no se navega ni se enseñan mensajes.
  Future<bool> blockUser(String userId) async {
    if (_service == null) return false;
    _error = null;
    try {
      await _service!.blockUser(userId);
      // Se marca en local para que las listas reaccionen sin recargar.
      _blockedIds.add(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _limpiar(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    if (_service == null) return false;
    _error = null;
    try {
      await _service!.unblockUser(userId);
      _blockedIds.remove(userId);
      _blocked.removeWhere((b) => b.userId == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _limpiar(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportUser(
    String userId,
    String reason, {
    String? messageId,
  }) async {
    if (_service == null) return false;
    _error = null;
    try {
      await _service!.reportUser(userId, reason, messageId: messageId);
      return true;
    } catch (e) {
      _error = _limpiar(e);
      notifyListeners();
      return false;
    }
  }

  /// Las excepciones de Dart llegan como "Exception: texto"; se recorta el
  /// prefijo para no enseñárselo a nadie.
  String _limpiar(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

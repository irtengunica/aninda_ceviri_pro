// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';

/// Cihaz hafızasına (SharedPreferences) veri kaydetme ve okuma işlemlerini yönetir.
class StorageService {
  static const _historyKey = 'translation_history';

  /// Kaydedilmiş çeviri geçmişini yükler.
  Future<List<TranslationHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    if (historyString != null) {
      final List<dynamic> historyJson = jsonDecode(historyString);
      return historyJson
          .map((item) => TranslationHistoryItem.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Mevcut çeviri geçmişini cihaza kaydeder.
  Future<void> saveHistory(List<TranslationHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final String historyString = jsonEncode(
      history.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_historyKey, historyString);
  }
}

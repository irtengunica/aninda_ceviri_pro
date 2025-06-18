// lib/models/history_model.dart

/// Her bir çeviri geçmişi öğesini temsil eden veri modeli.
class TranslationHistoryItem {
  final String sourceText;
  final String translatedText;
  final String sourceLangCode;
  final String targetLangCode;

  TranslationHistoryItem({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLangCode,
    required this.targetLangCode,
  });

  /// Bu nesneyi JSON formatına (Map) dönüştürür.
  Map<String, dynamic> toJson() => {
    'sourceText': sourceText,
    'translatedText': translatedText,
    'sourceLangCode': sourceLangCode,
    'targetLangCode': targetLangCode,
  };

  /// JSON formatından (Map) bir nesne oluşturur.
  factory TranslationHistoryItem.fromJson(Map<String, dynamic> json) =>
      TranslationHistoryItem(
        sourceText: json['sourceText'],
        translatedText: json['translatedText'],
        sourceLangCode: json['sourceLangCode'],
        targetLangCode: json['targetLangCode'],
      );
}

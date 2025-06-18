// lib/models/language_model.dart

/// Her bir dilin bilgilerini tutan veri modeli.
class Language {
  final String name; // Ekranda görünecek ad (Örn: "Türkçe")
  final String translateCode; // Çeviri paketi için kod (Örn: "tr")
  final String speechCode; // Konuşma ve seslendirme için kod (Örn: "tr-TR")

  Language(this.name, this.translateCode, this.speechCode);

  // Dropdown menülerinde doğru karşılaştırma için gerekli
  @override
  bool operator ==(Object other) =>
      other is Language && other.translateCode == translateCode;

  @override
  int get hashCode => translateCode.hashCode;
}

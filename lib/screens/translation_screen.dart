// lib/screens/translation_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/history_model.dart';
import '../models/language_model.dart';
import '../services/ocr_service.dart';
import '../services/storage_service.dart';
import '../widgets/language_selector_widget.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});
  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  // --- Servisler ve Controller'lar ---
  final StorageService _storageService = StorageService();
  final OcrService _ocrService = OcrService();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();
  final TextEditingController _sourceTextController = TextEditingController();

  // --- Durum Değişkenleri ---
  String _translatedText = "";
  bool _isListening = false;
  bool _speechToTextInitialized = false; // YENİ DEĞİŞKEN
  bool _isProcessing =
      false; // Çeviri veya OCR işlemi için genel yükleme durumu
  List<TranslationHistoryItem> _history = [];

  // --- Dil Verileri ---
  final List<Language> languages = [
    Language("Türkçe", "tr", "tr-TR"),
    Language("English", "en", "en-US"),
    Language("Deutsch", "de", "de-DE"),
    Language("Español", "es", "es-ES"),
    Language("Français", "fr", "fr-FR"),
    Language("Italiano", "it", "it-IT"),
  ];
  late Language _selectedSourceLanguage;
  late Language _selectedTargetLanguage;

  @override
  void initState() {
    super.initState();
    _selectedSourceLanguage = languages[0];
    _selectedTargetLanguage = languages[1];
    _initServices();
  }

  @override
  void dispose() {
    _sourceTextController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    _speechToTextInitialized =
        await _speechToText.initialize(); // DEĞİŞİKLİK BURADA
    _history = await _storageService.loadHistory();
    setState(() {});
  }

  // --- AKSİYONLAR ---

  // lib/screens/translation_screen.dart içinde, _TranslationScreenState sınıfına ekleyin

  void _showHistorySheet() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Henüz çeviri geçmişiniz yok.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Çeviri Geçmişi",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    title: Text(
                      item.sourceText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.translatedText,
                      style: const TextStyle(
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Pencereyi kapat
                      _sourceTextController.text = item.sourceText;
                      setState(() {
                        _translatedText = item.translatedText;
                        _selectedSourceLanguage = languages.firstWhere(
                          (lang) => lang.translateCode == item.sourceLangCode,
                        );
                        _selectedTargetLanguage = languages.firstWhere(
                          (lang) => lang.translateCode == item.targetLangCode,
                        );
                      });
                      _speak(item.translatedText, item.targetLangCode);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _startListening() async {
    if (_isProcessing || _isListening) return;
    // Artık bu kontrole gerek yok, çünkü buton zaten pasif olacak.
    // if (!_speechToTextInitialized) { ... }

    _sourceTextController.clear();
    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      localeId: _selectedSourceLanguage.speechCode,
      onResult: (result) {
        _sourceTextController.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _isListening = false);
          _translate();
        }
      },
    );
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _translateWithOcr(ImageSource source) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });
    final recognizedText = await _ocrService.processImage(source);
    if (recognizedText != null && recognizedText.isNotEmpty) {
      _sourceTextController.text = recognizedText;
      _translate();
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _translate() async {
    final textToTranslate = _sourceTextController.text;
    if (textToTranslate.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isProcessing = true;
      _translatedText = "";
    });

    try {
      var translation = await _translator.translate(
        textToTranslate,
        from: _selectedSourceLanguage.translateCode,
        to: _selectedTargetLanguage.translateCode,
      );
      final translatedTextValue = translation.text;
      _saveToHistory(textToTranslate, translatedTextValue);
      setState(() {
        _translatedText = translatedTextValue;
      });
      _speak(_translatedText, _selectedTargetLanguage.speechCode);
    } on SocketException catch (_) {
      _showErrorDialog(
        "İnternet Bağlantı Hatası",
        "Lütfen internet bağlantınızı kontrol edip tekrar deneyin.",
      );
    } catch (e) {
      _showErrorDialog("Çeviri Hatası", "Bir hata oluştu: ${e.toString()}");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // --- YARDIMCI FONKSİYONLAR ---

  Future<void> _speak(String text, String langCode) async {
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(text);
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Çeviri panoya kopyalandı!")));
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Tamam"),
              ),
            ],
          ),
    );
  }

  void _saveToHistory(String sourceText, String translatedText) {
    final item = TranslationHistoryItem(
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLangCode: _selectedSourceLanguage.translateCode,
      targetLangCode: _selectedTargetLanguage.translateCode,
    );
    setState(() {
      _history.removeWhere((h) => h.sourceText == sourceText);
      _history.insert(0, item);
      if (_history.length > 50) _history.removeLast();
    });
    _storageService.saveHistory(_history);
  }

  // --- BUILD METODU ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anında Çeviri Pro"),
        centerTitle: true, // YENİ: AppBar'a eylem butonu ekleme
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Çeviri Geçmişi',
            onPressed: _showHistorySheet,
          ),
        ],
      ),
      // ... build metodunun geri kalanı aynı ...),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              LanguageSelectorWidget(
                languages: languages,
                sourceLanguage: _selectedSourceLanguage,
                targetLanguage: _selectedTargetLanguage,
                onSourceChanged:
                    (lang) => setState(() => _selectedSourceLanguage = lang),
                onTargetChanged:
                    (lang) => setState(() => _selectedTargetLanguage = lang),
                onSwap:
                    () => setState(() {
                      final tempLang = _selectedSourceLanguage;
                      _selectedSourceLanguage = _selectedTargetLanguage;
                      _selectedTargetLanguage = tempLang;
                    }),
              ),
              const SizedBox(height: 16),
              _buildSourceCard(),
              const SizedBox(height: 16),
              _buildTranslationCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        // YENİ KONTROL: Eğer işlem yapılıyorsa VEYA konuşma servisi hazır değilse butonu pasif yap.
        onPressed:
            (_isProcessing || !_speechToTextInitialized)
                ? null
                : (_isListening ? _stopListening : _startListening),
        backgroundColor:
            (_isProcessing || !_speechToTextInitialized)
                ? Colors
                    .grey // Pasifken gri yap
                : (_isListening
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary),
        child:
            _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- WIDGET OLUŞTURUCU METOTLAR ---

  Card _buildSourceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _sourceTextController,
              maxLines: 8,
              minLines: 3,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: "Çevirmek için yazın, konuşun veya resim seçin...",
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined),
                      tooltip: "Galeriden Seç",
                      onPressed: () => _translateWithOcr(ImageSource.gallery),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: "Kameradan Çek",
                      onPressed: () => _translateWithOcr(ImageSource.camera),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _translate,
                  icon: const Icon(Icons.translate),
                  label: const Text("ÇEVİR"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Card _buildTranslationCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Çeviri (${_selectedTargetLanguage.translateCode.toUpperCase()})",
                  style: const TextStyle(color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined, size: 20),
                      tooltip: "Tekrar Dinle",
                      onPressed:
                          () => _speak(
                            _translatedText,
                            _selectedTargetLanguage.speechCode,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      tooltip: "Panoya Kopyala",
                      onPressed: () => _copyToClipboard(_translatedText),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isProcessing && _translatedText.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              SelectableText(
                _translatedText,
                style: const TextStyle(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

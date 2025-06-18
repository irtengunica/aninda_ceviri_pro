// lib/services/ocr_service.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // DOĞRU IMPORT BURADA
import 'package:image_picker/image_picker.dart';

/// Kamera veya galeriden alınan resimlerdeki metinleri tanıma (OCR) işlemini yönetir.
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  /// Verilen kaynaktan (kamera/galeri) bir resim seçer ve metni tanır.
  Future<String?> processImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return null; // Kullanıcı resim seçmekten vazgeçti

      final InputImage inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      return recognizedText.text;
    } catch (e) {
      print("OCR Servis Hatası: $e");
      return null;
    }
  }

  /// Servis kapatıldığında kaynakları serbest bırakır.
  void dispose() {
    _textRecognizer.close();
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/food_scan_result.dart';
import '../services/food_recognition_service.dart';
import '../widgets/health_glass.dart';

class FoodScanScreen extends StatefulWidget {
  final ValueChanged<FoodScanResult> onResult;

  const FoodScanScreen({super.key, required this.onResult});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  final _picker = ImagePicker();
  final _recognitionService = FoodRecognitionService();

  XFile? _image;
  bool _isPickingImage = false;
  bool _isRecognizing = false;
  String? _errorMessage;
  String? _progressMessage;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
      _errorMessage = null;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 75,
      );
      if (!mounted) return;
      setState(() {
        _image = image ?? _image;
        _isPickingImage = false;
      });
    } on PlatformException catch (error) {
      _showError('Не удалось открыть камеру или галерею: ${error.message}');
    } on FileSystemException catch (error) {
      _showError('Не удалось прочитать выбранное фото: ${error.message}');
    }
  }

  Future<void> _recognizeImage() async {
    final image = _image;
    if (image == null || _isRecognizing) return;

    setState(() {
      _isRecognizing = true;
      _errorMessage = null;
      _progressMessage = 'Отправляем фото в Gemini...';
    });
    try {
      final bytes = await image.readAsBytes();
      final apiKey =
          Hive.box('settingsBox').get(FoodRecognitionService.apiKeyStorageKey)
              as String? ??
          '';
      final result = await _recognitionService.recognize(
        imageBytes: bytes,
        mimeType: _mimeTypeFor(image.name),
        apiKey: apiKey,
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _progressMessage = status);
        },
      );
      if (!mounted) return;
      setState(() => _progressMessage = null);
      widget.onResult(result);
    } on FoodRecognitionException catch (error) {
      _showError(error.message);
    } on FileSystemException catch (error) {
      _showError('Не удалось прочитать фото: ${error.message}');
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Не удалось распознать блюдо: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
          _progressMessage = null;
        });
      }
    }
  }

  String _mimeTypeFor(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isPickingImage = false;
      _isRecognizing = false;
      _progressMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return HealthBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 94),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'ИИ распознавание блюда',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сфотографируйте блюдо или выберите фото из галереи. '
                'Gemini оценит ингредиенты и КБЖУ — результат можно будет проверить.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Оценка по фото приблизительная. Фотография отправляется в Google Gemini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(26),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.56),
                      child: image == null
                          ? const Center(
                              child: Icon(
                                Icons.no_food_outlined,
                                size: 80,
                                color: Color(0xFF79A38C),
                              ),
                            )
                          : Image.file(File(image.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPickingImage || _isRecognizing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Камера'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPickingImage || _isRecognizing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Галерея'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isRecognizing && _progressMessage != null) ...[
                Text(
                  _progressMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF66786C),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: image == null || _isRecognizing || _isPickingImage
                      ? null
                      : _recognizeImage,
                  icon: _isRecognizing || _isPickingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isPickingImage
                        ? 'Открываем фото...'
                        : _isRecognizing
                        ? 'Распознаём блюдо...'
                        : 'Распознать блюдо',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6D9B7E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

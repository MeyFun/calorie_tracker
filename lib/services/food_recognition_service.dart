import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/food_scan_result.dart';

class FoodRecognitionException implements Exception {
  final String message;

  const FoodRecognitionException(this.message);

  @override
  String toString() => message;
}

class FoodRecognitionService {
  static const apiKeyStorageKey = 'geminiApiKey';
  static const _modelName = 'gemini-3.8-flash';
  static const _requestTimeout = Duration(seconds: 18);
  static const _maxAttempts = 3;

  Future<FoodScanResult> recognize({
    required Uint8List imageBytes,
    required String mimeType,
    required String apiKey,
    void Function(String status)? onStatus,
  }) async {
    final normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      throw const FoodRecognitionException(
        'Сначала добавьте API-ключ Gemini в профиле.',
      );
    }

    final endpoint = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_modelName:generateContent',
    );
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': mimeType.isEmpty ? 'image/jpeg' : mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      },
    });

    http.Response? response;
    Object? lastNetworkError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        response = await http
            .post(
              endpoint,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': normalizedApiKey,
              },
              body: requestBody,
            )
            .timeout(_requestTimeout);
        lastNetworkError = null;
      } on TimeoutException {
        lastNetworkError = TimeoutException(
          'Gemini не ответил за ${_requestTimeout.inSeconds} секунд.',
        );
      } on http.ClientException catch (error) {
        lastNetworkError = error;
      }

      final hasTransientResponse =
          response != null && _isTransientStatus(response.statusCode);
      final hasTransientNetworkError = lastNetworkError != null;
      if (!hasTransientResponse && !hasTransientNetworkError) break;
      if (attempt == _maxAttempts) break;

      final retryDelay = Duration(seconds: attempt);
      final retryMessage = lastNetworkError != null
          ? 'Проблема со связью. Повторная попытка '
                '${attempt + 1} из $_maxAttempts...'
          : response?.statusCode == 429
          ? 'Лимит Gemini временно исчерпан. Повторная попытка '
                '${attempt + 1} из $_maxAttempts...'
          : 'Gemini перегружен. Повторная попытка '
                '${attempt + 1} из $_maxAttempts...';
      onStatus?.call(retryMessage);
      await Future<void>.delayed(retryDelay);
    }

    if (lastNetworkError is TimeoutException) {
      throw const FoodRecognitionException(
        'Gemini не ответил за отведённое время после нескольких попыток. '
        'Проверьте интернет и попробуйте позже.',
      );
    }
    if (lastNetworkError is http.ClientException) {
      throw FoodRecognitionException(
        'Не удалось связаться с Gemini после нескольких попыток: '
        '${lastNetworkError.message}',
      );
    }
    if (response == null) {
      throw const FoodRecognitionException(
        'Не удалось получить ответ Gemini. Проверьте интернет и попробуйте ещё раз.',
      );
    }

    if (response.statusCode != 200) {
      throw FoodRecognitionException(
        _apiErrorMessage(response.statusCode, response.body),
      );
    }

    final responseJson = _decodeJsonObject(
      response.body,
      'Gemini вернул некорректный ответ.',
    );
    final candidates = responseJson['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final feedback = responseJson['promptFeedback'];
      final reason = feedback is Map ? feedback['blockReason'] : null;
      throw FoodRecognitionException(
        reason == null
            ? 'Gemini не смог распознать это фото. Попробуйте другое изображение.'
            : 'Запрос остановлен фильтром безопасности Gemini ($reason).',
      );
    }

    final candidate = candidates.first;
    final content = candidate is Map ? candidate['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    String? text;
    if (parts is List) {
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          text = part['text'] as String;
          break;
        }
      }
    }
    if (text == null || text.trim().isEmpty) {
      throw const FoodRecognitionException(
        'Gemini не вернул данные о блюде. Попробуйте сделать фото ещё раз.',
      );
    }

    final resultJson = _decodeJsonObject(
      text,
      'Gemini вернул данные блюда в неожиданном формате.',
    );
    try {
      return FoodScanResult.fromJson(resultJson);
    } on FormatException catch (error) {
      throw FoodRecognitionException(error.message);
    }
  }

  bool _isTransientStatus(int statusCode) =>
      statusCode == 408 ||
      statusCode == 429 ||
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  String _apiErrorMessage(int statusCode, String body) {
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          message = error['message'] as String;
        }
      }
    } on FormatException {
      message = null;
    }

    final details = message ?? 'Сервер не вернул описание ошибки.';
    if (statusCode == 400 || statusCode == 404) {
      return 'Gemini отклонил запрос ($statusCode): $details '
          'Проверьте модель, формат фото и доступность модели для вашего API-ключа.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Gemini отклонил API-ключ ($statusCode): $details';
    }
    if (statusCode == 429) {
      return 'Лимит запросов Gemini всё ещё превышен после нескольких попыток '
          '(429): $details Попробуйте через минуту.';
    }
    if (statusCode == 503) {
      return 'Сервер Gemini остаётся перегружен после $_maxAttempts попыток '
          '(503): $details Попробуйте позже.';
    }
    return 'Ошибка Gemini ($statusCode): $details';
  }

  Map<String, dynamic> _decodeJsonObject(String text, String errorMessage) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw FoodRecognitionException(errorMessage);
    }
    throw FoodRecognitionException(errorMessage);
  }

  static const _prompt = '''
Проанализируй фотографию блюда для дневника питания.
Верни только JSON с полями:
"dish_name" (название блюда по-русски),
"ingredients" (массив ингредиентов по-русски),
"calories_per_100g", "protein_per_100g", "fat_per_100g", "carbs_per_100g" (числа, КБЖУ на 100 г готового блюда),
"estimated_weight_g" (число, оценка веса всей видимой порции в граммах).
Оцени только то, что можно разумно предположить по изображению;
не выдумывай точность и используй реалистичные приблизительные значения.
Если блюдо или размер порции трудно определить, всё равно верни наиболее осторожную оценку.
''';
}

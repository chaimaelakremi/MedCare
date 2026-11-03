import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

// Provided at build time, never hardcoded:
//   flutter run --dart-define-from-file=.env
// See .env.example. When the key is missing the scanner is disabled.
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
const _model =
    String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

const _prompt =
    'This is a medical prescription. Extract the FIRST medication and return ONLY valid JSON: '
    '{"name":"medication name","dose":"dosage with unit e.g. 500mg","frequency":"daily|twice_daily|thrice_daily|weekly","times":["08:00"]}. '
    'Times use 24h HH:mm format. '
    'If the image is not a prescription or is unreadable, return {"error":"not_a_prescription"}.';

const _frequencies = {'daily', 'twice_daily', 'thrice_daily', 'weekly'};

class ScannedMedication {
  final String name;
  final String dose;
  final String frequency;
  final List<String> times;

  const ScannedMedication({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.times,
  });
}

class PrescriptionScanner {
  /// False when no GEMINI_API_KEY was provided at build time.
  static bool get isAvailable => _apiKey.isNotEmpty;

  /// Returns the first medication found, or null when the image is not a
  /// readable prescription. Throws on network / API errors.
  static Future<ScannedMedication?> scan(XFile image) async {
    if (!isAvailable) return null;

    final bytes = await image.readAsBytes();
    final model = GenerativeModel(
      model: _model,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0,
      ),
    );

    final response = await model.generateContent([
      Content.multi([
        DataPart(_mime(image.name), bytes),
        TextPart(_prompt),
      ]),
    ]);

    final text = response.text ?? '';
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
    if (jsonMatch == null) return null;

    try {
      final med = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      if (med['error'] != null) return null;

      final name = (med['name'] as String? ?? '').trim();
      if (name.isEmpty) return null;

      final frequency = med['frequency'] as String? ?? 'daily';
      final times = (med['times'] as List?)
              ?.whereType<String>()
              .where((t) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t))
              .toList() ??
          const <String>[];

      return ScannedMedication(
        name: name,
        dose: (med['dose'] as String? ?? '').trim(),
        frequency: _frequencies.contains(frequency) ? frequency : 'daily',
        times: times.isEmpty ? const ['08:00'] : times,
      );
    } on FormatException catch (e) {
      debugPrint('[PrescriptionScanner] Invalid JSON: $e');
      return null;
    }
  }

  static String _mime(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'heic') return 'image/heic';
    return 'image/jpeg';
  }
}

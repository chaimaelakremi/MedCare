import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Replace with your Anthropic API key
const _anthropicKey = 'ADD_ANTHROPIC_API_KEY_HERE';

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
  static Future<ScannedMedication?> scan(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Data = base64Encode(bytes);
    final mimeType = _mime(image.name);

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 512,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mimeType,
                  'data': base64Data,
                },
              },
              {
                'type': 'text',
                'text':
                    'This is a medical prescription. Extract the FIRST medication and return ONLY valid JSON (no markdown, no explanation): '
                    '{"name":"medication name","dose":"dosage with unit e.g. 500mg","frequency":"daily|twice_daily|thrice_daily","times":["08:00"]}. '
                    'If not a prescription or unreadable, return {"error":"not_a_prescription"}.',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (data['content'] as List?)?.first['text'] as String? ?? '';

    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
    if (jsonMatch == null) return null;

    final med = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    if (med['error'] != null) return null;

    return ScannedMedication(
      name: med['name'] as String? ?? '',
      dose: med['dose'] as String? ?? '',
      frequency: med['frequency'] as String? ?? 'daily',
      times: (med['times'] as List?)?.cast<String>() ?? ['08:00'],
    );
  }

  static String _mime(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    if (ext == 'png') return 'image/png';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }
}

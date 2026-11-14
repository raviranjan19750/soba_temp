import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  String? _apiKey;

  void initialize() {
    _apiKey = dotenv.env['OPENAI_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty || _apiKey == 'your_openai_api_key_here') {
      print('Warning: OPENAI_API_KEY not found in .env file or not configured');
    } else {
      print('OpenAI API key loaded (length: ${_apiKey!.length})');
    }
  }

  Future<String> generateSuggestion({
    required String fieldType, // 'Mission', 'Vision', or 'Values'
    required String existingText,
  }) async {
    try {
      // Always get the latest API key from dotenv
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
        throw Exception('API key not valid. Please pass a valid API key.');
      }

      final prompt = _buildPrompt(fieldType, existingText);
      
      // OpenAI Chat Completions API endpoint
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final requestBody = {
        'model': 'gpt-4o-mini', // Using GPT-4o-mini (cost-effective and fast)
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final choices = responseData['choices'];
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            final content = message['content'] as String;
            // Strip any formatting that might be present
            return _stripFormatting(content);
          }
        }
        throw Exception('No content in response: ${response.body}');
      } else {
        // Better error handling
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 
                               errorData['error']?.toString() ?? 
                               response.body;
          throw Exception('API Error (${response.statusCode}): $errorMessage');
        } catch (e) {
          throw Exception('API Error (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Error generating AI suggestion: $e');
    }
  }

  String _buildPrompt(String fieldType, String existingText) {
    final basePrompt = existingText.trim().isEmpty
        ? 'Generate a professional and inspiring company $fieldType statement. Use plain text only - do not include any formatting, bold text, markdown, asterisks, or special characters. Just provide clean, readable text.'
        : 'Based on the following partial $fieldType text, complete and enhance it to create a comprehensive, professional, and inspiring company $fieldType statement. Maintain the tone and intent of what has been written:\n\n$existingText\n\nProvide a complete, polished $fieldType statement. Use plain text only - do not include any formatting, bold text, markdown, asterisks, or special characters. Just provide clean, readable text.';

    return basePrompt;
  }

  String _stripFormatting(String text) {
    // Remove markdown bold (**text**)
    text = text.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    // Remove markdown italic (*text*)
    text = text.replaceAll(RegExp(r'(?<!\*)\*([^*]+?)\*(?!\*)'), r'$1');
    // Remove HTML bold tags
    text = text.replaceAll(RegExp(r'<b>(.*?)</b>', caseSensitive: false), r'$1');
    text = text.replaceAll(RegExp(r'<strong>(.*?)</strong>', caseSensitive: false), r'$1');
    // Remove markdown headers
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Remove extra whitespace and newlines
    text = text.trim();
    
    return text;
  }
}



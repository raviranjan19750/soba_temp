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
    /// Free-form text assembled from the Company Background tab; may be empty.
    String? companyBackgroundContext,
  }) async {
    return _chatCompletion(
      prompt: _buildPrompt(
        fieldType,
        existingText,
        companyBackgroundContext,
      ),
      maxTokens: 500,
      temperature: 0.7,
    );
  }

  Future<String> generateInitiativeMetricSuggestion({
    required String area,
    required String goal,
    required String initiative,
  }) async {
    final prompt = '''You help leadership teams define KPIs for strategic initiatives.

Strategic area: ${area.trim().isEmpty ? 'General' : area.trim()}
Year 1 goal: ${goal.trim().isEmpty ? 'Not specified' : goal.trim()}
Initiative: ${initiative.trim().isEmpty ? 'Not specified' : initiative.trim()}

Suggest ONE concise, measurable KPI metric name to track quarterly progress on this initiative.

Rules:
- Return only the metric name (example: "Customer retention rate %" or "Monthly recurring revenue")
- No explanation, bullets, quotes, or markdown
- Maximum 8 words
- Prefer metrics that can be tracked quarterly with a numeric target''';

    final result = await _chatCompletion(
      prompt: prompt,
      maxTokens: 40,
      temperature: 0.4,
    );
    return result.split('\n').first.trim();
  }

  /// Drafts Customer Insights or Market Research for Step 2 External Assessment.
  Future<String> generateExternalAssessmentSuggestion({
    required String fieldType,
    required String existingText,
    required String companyContext,
  }) async {
    final hasContext = companyContext.trim().isNotEmpty;
    final hasDraft = existingText.trim().isNotEmpty;

    final prompt = '''You help leadership teams complete an external strategic assessment.

## Company & internal context
${hasContext ? companyContext.trim() : 'Limited company context provided. Infer carefully from general industry patterns and note assumptions.'}

## Field to draft
$fieldType

## Current draft
${hasDraft ? existingText.trim() : '(empty)'}

## Task
Write a practical $fieldType draft for strategic planning (about 3–6 short paragraphs or clear prose sections). Ground the answer in the company context above. Where helpful, use widely known industry / market / customer patterns as external reference points—but do not invent specific proprietary data, named survey scores, or fake citations.

${fieldType == 'Customer Insights' ? 'Cover satisfaction themes, unmet needs, buying behavior, and what customers value or complain about.' : ''}
${fieldType == 'Market Research Key Takeaways' ? 'Cover industry trends, competitor moves, pricing dynamics, and other market research implications for this company.' : ''}

${hasDraft ? 'Improve and expand the current draft while preserving the user\'s intent.' : 'Create a strong first draft the user can edit.'}

Output rules: plain text only. No markdown headings, bold, bullets with asterisks, or numbered lists. Use short paragraphs. Return only the $fieldType draft.''';

    return _chatCompletion(
      prompt: prompt,
      maxTokens: 700,
      temperature: 0.55,
    );
  }

  /// Drafts all six PESTEL dimensions for Step 2 External Assessment.
  Future<Map<String, String>> generatePestelSuggestion({
    required String companyContext,
    required Map<String, String> existingPestel,
  }) async {
    final existingBlock = existingPestel.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '${e.key}: ${e.value.trim()}')
        .join('\n');

    final prompt = '''You help leadership teams complete a PESTEL analysis for strategic planning.

## Company & internal context
${companyContext.trim().isEmpty ? 'Limited company context provided. Use careful industry assumptions.' : companyContext.trim()}

## Existing PESTEL drafts (may be empty)
${existingBlock.isEmpty ? '(none yet)' : existingBlock}

## Task
Draft concise PESTEL notes tailored to this company. Use the company context and common external / industry knowledge. Do not invent fake statistics or named sources.

Return EXACTLY these six labeled lines (one paragraph each after the label). Do not add other text:

POLITICAL: ...
ECONOMIC: ...
SOCIAL: ...
TECHNOLOGICAL: ...
ENVIRONMENTAL: ...
LEGAL: ...

Each value should be 1–3 sentences. Plain text only. No markdown.''';

    final raw = await _chatCompletion(
      prompt: prompt,
      maxTokens: 900,
      temperature: 0.5,
    );

    return _parseLabeledSections(
      raw,
      const [
        'POLITICAL',
        'ECONOMIC',
        'SOCIAL',
        'TECHNOLOGICAL',
        'ENVIRONMENTAL',
        'LEGAL',
      ],
    );
  }

  Map<String, String> _parseLabeledSections(String raw, List<String> labels) {
    final result = <String, String>{for (final label in labels) label: ''};
    final pattern = RegExp(
      '^(${labels.join('|')}):\\s*(.*)\$',
      multiLine: true,
      caseSensitive: false,
    );
    final matches = pattern.allMatches(raw).toList();
    for (var i = 0; i < matches.length; i++) {
      final label = matches[i].group(1)!.toUpperCase();
      final start = matches[i].group(2) ?? '';
      final end = i + 1 < matches.length
          ? matches[i + 1].start
          : raw.length;
      final rest = raw.substring(matches[i].end, end).trim();
      final value = [start.trim(), if (rest.isNotEmpty) rest]
          .where((s) => s.isNotEmpty)
          .join('\n')
          .trim();
      final key = labels.firstWhere(
        (l) => l.toUpperCase() == label,
        orElse: () => label,
      );
      result[key] = value;
    }
    return result;
  }

  Future<String> _chatCompletion({
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'your_openai_api_key_here') {
        throw Exception('API key not valid. Please pass a valid API key.');
      }

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final choices = responseData['choices'];
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            return _stripFormatting(message['content'] as String);
          }
        }
        throw Exception('No content in response: ${response.body}');
      } else {
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

  String _buildPrompt(
    String fieldType,
    String existingText,
    String? companyBackgroundContext,
  ) {
    final hasBg = companyBackgroundContext != null &&
        companyBackgroundContext.trim().isNotEmpty;

    final contextBlock = hasBg
        ? '''## Company background (from the user's Company Background tab)
${companyBackgroundContext.trim()}

Ground the $fieldType in this context. Only reference industries, customers, geography, offerings, or scale when it fits these facts.'''
        : '''## Company background
The Company Background tab is empty or not filled in yet. Propose a strong, adaptable company $fieldType the user can refine later; use any draft text below if it helps.''';

    final draftBlock = existingText.trim().isEmpty
        ? 'The draft field is empty. Generate a concise, professional company $fieldType suitable for strategic planning (about 2–4 sentences, or for Values a short paragraph or several clear principles in plain prose).'
        : '''The user's current draft:
${existingText.trim()}

Improve and complete this into a polished company $fieldType while preserving their intent and voice.''';

    return '''You help leadership teams define mission, vision, and values.

$contextBlock

## Task
$draftBlock

Output rules: plain text only. No markdown, bullets, bold, asterisks, numbered lists, or headings. Return only the final $fieldType text.''';
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



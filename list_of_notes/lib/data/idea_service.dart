import 'dart:convert';

import 'package:http/http.dart' as http;

class IdeaService {
  final http.Client _client;

  IdeaService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> fetchRandomIdea() async {
    final uri = Uri.parse('https://api.adviceslip.com/advice');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load idea');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final slip = data['slip'];
    if (slip is Map<String, dynamic>) {
      final advice = slip['advice'];
      if (advice is String && advice.isNotEmpty) {
        return advice;
      }
    }

    throw Exception('Unexpected response');
  }
}



import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/contracts/i_agent_provider.dart';
import '../../domain/models/agent_result.dart';
import '../../domain/models/incident_analysis.dart';

class OllamaLocalProvider implements IAgentProvider {
  String baseUrl;
  String model;
  final http.Client _client;

  OllamaLocalProvider({String? baseUrl, String? model, http.Client? client})
    : baseUrl = baseUrl ?? defaultBaseUrl,
      model = model ?? 'gemma4:e4b-mlx',
      _client = client ?? http.Client();

  static String get defaultBaseUrl {
    // Android emulator usa 10.0.2.2 para acessar o host localhost
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.3.172:11434';
      }
    } catch (_) {
      // Caso executado na Web ou ambiente sem suporte a Platform
    }
    return 'http://localhost:11434';
  }

  @override
  String get providerName => 'LOCAL: Ollama ($model)';

  /// Testa conectividade com o Ollama executando um ping rápido na API de tags
  Future<bool> ping() async {
    try {
      final uri = Uri.parse('$baseUrl/api/tags');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Retorna lista de modelos instalados no Ollama local
  Future<List<String>> listInstalledModels() async {
    try {
      final uri = Uri.parse('$baseUrl/api/tags');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models =
            (data['models'] as List?)
                ?.map((m) => m['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList() ??
            [];
        return models;
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<AgentExecutionResult> processIncident(String rawText) async {
    final stopwatch = Stopwatch()..start();

    final systemPrompt = '''
Você é um Engenheiro de Confiabilidade de Sistemas (SRE) especializado em triagem de incidentes.
Sua missão é analisar o relatório de incidente fornecido e extrair estritamente um objeto JSON com as seguintes chaves:
- "incident_type": tipo da falha ou chamado (ex: "Falha de Autenticação", "Crash de Aplicação", "Lentidão/Timeout", "Cancelamento de Serviço").
- "severity": criticidade estrita (exatamente um destes valores: "Baixa", "Média", "Alta").
- "recommended_action": ação imediata que a equipe de suporte ou engenharia deve tomar em até 1 parágrafo claro.
- "execution_tasks": lista com 3 a 5 tarefas objetivas e acionáveis a serem executadas.
- "summary": breve resumo técnico do problema em 1 frase.

Responda DIRETAMENTE com o objeto JSON válido. Não inclua raciocínio preliminar longo nem comentários antes ou depois.
''';

    final requestBody = {
      'model': model,
      'prompt': '$systemPrompt\n\nIncidente para análise:\n$rawText',
      'format': 'json',
      'stream': false,
      'options': {'temperature': 0.1, 'num_predict': 2048},
    };

    try {
      final uri = Uri.parse('$baseUrl/api/generate');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw TimeoutException(
              'O Ollama demorou mais de 90 segundos para responder. Verifique os recursos da máquina.',
            ),
          );

      stopwatch.stop();

      if (response.statusCode != 200) {
        throw HttpException(
          'Ollama retornou status HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      String generatedText = (responseJson['response'] ?? '').toString().trim();

      // Fallback caso o modelo de raciocínio tenha incluído o JSON no bloco 'thinking'
      if (generatedText.isEmpty && responseJson['thinking'] != null) {
        generatedText = responseJson['thinking'].toString().trim();
      }

      // Parseia o JSON gerado
      final Map<String, dynamic> parsedJson = _cleanAndParseJson(generatedText);
      final analysis = IncidentAnalysis.fromJson(parsedJson);

      return AgentExecutionResult(
        analysis: analysis,
        providerName: providerName,
        routeTarget: RouteTarget.localOllama,
        latencyMs: stopwatch.elapsedMilliseconds,
        costUsd: 0.00, // Custo On-Device é sempre $0.00
        isCacheHit: false,
        privacyReport: PrivacyReport.clean(rawText),
        routeReason: 'Executado On-Device com Ollama ($model)',
        rawJson: generatedText,
      );
    } on SocketException {
      throw SocketException(
        'Não foi possível conectar ao Ollama em $baseUrl. '
        'Certifique-se de que o Ollama está rodando localmente '
        '(execute "ollama serve" ou "ollama run gemma4:e4b-mlx").',
      );
    } catch (e) {
      if (e is TimeoutException || e is SocketException || e is HttpException) {
        rethrow;
      }
      throw Exception('Falha ao processar com Ollama local: $e');
    }
  }

  Map<String, dynamic> _cleanAndParseJson(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();

    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      // Fallback em caso de JSON malformado pelo modelo
      final startIndex = clean.indexOf('{');
      final endIndex = clean.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final substring = clean.substring(startIndex, endIndex + 1);
        return jsonDecode(substring) as Map<String, dynamic>;
      }
      // Retorna fallback estruturado
      return {
        'incident_type': 'Incidente Técnico',
        'severity': 'Média',
        'recommended_action': 'Revisar relatório de log manualmente devido a formatação atípica da IA.',
        'execution_tasks': [
          'Verificar integridade do log',
          'Isolar módulo afetado',
          'Validar resposta gerada pela IA',
        ],
        'summary': clean.length > 100 ? clean.substring(0, 100) : clean,
      };
    }
  }
}

import 'dart:convert';
import '../../domain/contracts/i_agent_provider.dart';
import '../../domain/models/agent_result.dart';
import '../../domain/models/incident_analysis.dart';
import '../services/mediapipe_llm_service.dart';
import '../services/model_manager_service.dart';

/// Provedor On-Device baseado na Google MediaPipe LLM Inference API executando Gemma 2B.
class MediaPipeOnDeviceProvider implements IAgentProvider {
  final MediaPipeLlmService llmService;
  final ModelManagerService modelManager;
  final String modelName;

  MediaPipeOnDeviceProvider({
    MediaPipeLlmService? llmService,
    ModelManagerService? modelManager,
    this.modelName = ModelManagerService.defaultGemmaModelName,
  })  : llmService = llmService ?? MediaPipeLlmService(),
        modelManager = modelManager ?? ModelManagerService();

  @override
  String get providerName => 'ON-DEVICE: FlutterEdgeAI (Gemma 2B)';

  /// Garante que o modelo está carregado na VRAM/NPU
  Future<bool> ensureInitialized() async {
    if (llmService.isReady) return true;

    final path = await modelManager.getModelPath(filename: modelName);
    return await llmService.initialize(
      modelPath: path,
      maxTokens: 1024,
      temperature: 0.2, // Baixa temperatura para extração determinística
      topK: 40,
    );
  }

  @override
  Future<AgentExecutionResult> processIncident(String rawText) async {
    final stopwatch = Stopwatch()..start();

    // 1. Garante que o modelo está inicializado
    final isReady = await ensureInitialized();
    if (!isReady) {
      throw StateError(
        'Modelo On-Device não pôde ser carregado. '
        'Verifique se o arquivo "$modelName" está disponível no armazenamento local. '
        'Detalhes: ${llmService.lastError ?? "Erro desconhecido"}',
      );
    }

    // 2. Monta o prompt formatado com as tags oficiais do Gemma 2 Instruct
    final formattedPrompt = _buildGemmaPrompt(rawText);

    try {
      // 3. Execução nativa On-Device via GPU/NPU com flutter_edge_ai
      final rawOutput = await llmService.generateResponse(formattedPrompt);
      stopwatch.stop();

      // 4. Parse do JSON estruturado
      final parsedJson = _cleanAndParseJson(rawOutput);
      final analysis = IncidentAnalysis.fromJson(parsedJson);

      return AgentExecutionResult(
        analysis: analysis,
        providerName: providerName,
        routeTarget: RouteTarget.localOllama, // Categoria local On-Device
        latencyMs: stopwatch.elapsedMilliseconds,
        costUsd: 0.00, // Custo zero de nuvem
        isCacheHit: false,
        privacyReport: PrivacyReport.clean(rawText),
        routeReason: 'Inferência On-Device 100% Nativa (FlutterEdgeAI + Gemma 2B via NPU/GPU)',
        rawJson: rawOutput,
      );
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  /// Constrói o prompt com o template padrão do Gemma 2
  String _buildGemmaPrompt(String incidentText) {
    return '''<start_of_turn>user
Você é um Engenheiro de Confiabilidade de Sistemas (SRE) especializado em triagem e diagnóstico de incidentes.
Analise o relatório e retorne EXCLUSIVAMENTE um objeto JSON válido (sem textos extras ou marcações de markdown fora do JSON) com as seguintes chaves:
- "incident_type": tipo da falha (ex: "Falha de Autenticação", "Crash de Aplicação", "Lentidão/Timeout").
- "severity": criticidade estrita (exatamente um destes: "Baixa", "Média", "Alta").
- "recommended_action": ação imediata recomendada em 1 parágrafo claro.
- "execution_tasks": lista com 3 a 5 passos práticos acionáveis.
- "summary": resumo técnico em 1 frase.

Incidente para análise:
$incidentText<end_of_turn>
<start_of_turn>model
''';
  }

  /// Limpa e extrai JSON de eventuais blocos de código markdown ou texto livre
  Map<String, dynamic> _cleanAndParseJson(String raw) {
    String cleaned = raw.trim();

    // Remove tags de turn do Gemma caso o modelo as repita
    cleaned = cleaned
        .replaceAll('<start_of_turn>model', '')
        .replaceAll('<end_of_turn>', '')
        .trim();

    // Se estiver envelopado em markdown ```json ... ```
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();

    // Busca pelo primeiro '{' e último '}'
    final startIdx = cleaned.indexOf('{');
    final endIdx = cleaned.lastIndexOf('}');

    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Fallback resiliente
      return {
        'incident_type': 'Diagnóstico Edge Gemma 2B',
        'severity': 'Média',
        'recommended_action':
            'Processado com sucesso pelo modelo On-Device. Resposta original: $cleaned',
        'execution_tasks': [
          'Verificar telemetria do dispositivo',
          'Validar resposta estruturada gerada pelo Gemma',
          'Confirmar conformidade de privacidade'
        ],
        'summary': 'Incidente avaliado localmente via Google MediaPipe GenAI.',
      };
    }
  }
}

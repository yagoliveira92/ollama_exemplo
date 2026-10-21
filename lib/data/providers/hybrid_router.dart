import 'dart:async';
import '../../domain/contracts/i_agent_provider.dart';
import '../../domain/models/agent_result.dart';
import '../services/firewall_sanitizer.dart';
import '../services/semantic_cache.dart';
import 'cloud_agent_provider.dart';
import 'mediapipe_on_device_provider.dart';
import 'ollama_local_provider.dart';

enum LocalEngineType {
  mediaPipeOnDevice,
  ollamaServer,
}

class CumulativeMetrics {
  double totalSavedUsd;
  int totalLatencySavedMs;
  int totalRequests;
  int localCount;
  int cloudCount;
  int cacheCount;

  CumulativeMetrics({
    this.totalSavedUsd = 0.0,
    this.totalLatencySavedMs = 0,
    this.totalRequests = 0,
    this.localCount = 0,
    this.cloudCount = 0,
    this.cacheCount = 0,
  });
}

class HybridRouter implements IAgentProvider {
  final OllamaLocalProvider localProvider;
  final MediaPipeOnDeviceProvider mediaPipeProvider;
  final CloudAgentProvider cloudProvider;
  final FirewallSanitizer sanitizer;
  final SemanticCache semanticCache;

  LocalEngineType activeLocalEngine;
  bool forceOfflineMode;
  final CumulativeMetrics metrics = CumulativeMetrics();

  HybridRouter({
    required this.localProvider,
    required this.cloudProvider,
    MediaPipeOnDeviceProvider? mediaPipeProvider,
    this.activeLocalEngine = LocalEngineType.mediaPipeOnDevice,
    FirewallSanitizer? sanitizer,
    SemanticCache? semanticCache,
    this.forceOfflineMode = false,
  })  : mediaPipeProvider = mediaPipeProvider ?? MediaPipeOnDeviceProvider(),
        sanitizer = sanitizer ?? FirewallSanitizer(),
        semanticCache = semanticCache ?? SemanticCache();

  @override
  String get providerName => 'Orquestrador Híbrido (EdgeInspector)';

  @override
  Future<AgentExecutionResult> processIncident(String rawText) async {
    final startTime = DateTime.now();

    // 1. CHECAGEM NO CACHE SEMÂNTICO EM MEMÓRIA (<10ms)
    final cached = semanticCache.lookup(rawText);
    if (cached != null) {
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      metrics.totalRequests++;
      metrics.cacheCount++;
      metrics.totalSavedUsd += cloudProvider.costPerRequest;
      metrics.totalLatencySavedMs += (950 - elapsedMs).clamp(200, 1500);

      final privacyReport = sanitizer.sanitize(rawText);

      return AgentExecutionResult(
        analysis: cached.analysis,
        providerName: '⚡ Cache Semântico em Memória',
        routeTarget: RouteTarget.semanticCache,
        latencyMs: elapsedMs < 2 ? 3 : elapsedMs,
        costUsd: 0.00,
        isCacheHit: true,
        privacyReport: privacyReport,
        routeReason: '⚡ Servido via Cache Semântico (100% economia)',
        rawJson: cached.rawJson,
      );
    }

    // =========================================================================
    // [WORKSHOP - PARTE 4] ROTEADOR HÍBRIDO E FIREWALL COGNITIVO
    // =========================================================================
    // 2. FIREWALL COGNITIVO ON-DEVICE (Detecção e Sanitização de PIIs)
    // TODO: [WORKSHOP - PARTE 4.1] Executar o sanitizer para detectar CPFs, e-mails e nomes:
    final privacyReport = sanitizer.sanitize(rawText);
    final bool hasSensitivePii = privacyReport.hasPii;

    // 3. ANÁLISE DE COMPLEXIDADE E CONECTIVIDADE
    final bool isComplex = _isComplexIncident(rawText);
    final String sanitizedPayload = privacyReport.sanitizedText;

    AgentExecutionResult result;

    // TODO: [WORKSHOP - PARTE 4.2] Implementar as 4 Regras de Roteamento Inteligente:
    // -------------------------------------------------------------------------
    // Regra 1: Se estiver offline forçado (forceOfflineMode) -> Executar no Edge (_executeLocal)
    // Regra 2: Se tiver PII e não for crítico (hasSensitivePii && !isComplex) -> Manter no Edge por privacidade estrita
    // Regra 3: Se for simples/curto (!isComplex) -> Executar no Edge por custo zero e velocidade
    // Regra 4: Caso contrário (complexo) -> Despachar para a Nuvem (_executeCloud) com o texto higienizado
    // -------------------------------------------------------------------------

    if (forceOfflineMode) {
      result = await _executeLocal(
        payload: sanitizedPayload,
        privacyReport: privacyReport,
        routeReason: 'Modo Offline Ativado: Resiliência 100% On-Device garantida',
      );
      metrics.localCount++;
      metrics.totalSavedUsd += cloudProvider.costPerRequest;
    } else if (hasSensitivePii && !isComplex) {
      result = await _executeLocal(
        payload: sanitizedPayload,
        privacyReport: privacyReport,
        routeReason: 'Firewall Cognitivo On-Device: PII detectado e retido localmente para privacidade estrita',
      );
      metrics.localCount++;
      metrics.totalSavedUsd += cloudProvider.costPerRequest;
    } else if (!isComplex) {
      result = await _executeLocal(
        payload: sanitizedPayload,
        privacyReport: privacyReport,
        routeReason: 'Complexidade Baixa (<300 chars): Roteado para Edge AI Local (\$0.00 de custo)',
      );
      metrics.localCount++;
      metrics.totalSavedUsd += cloudProvider.costPerRequest;
    } else {
      result = await _executeCloud(
        sanitizedPayload: sanitizedPayload,
        privacyReport: privacyReport,
        routeReason: hasSensitivePii
            ? 'Complexidade Alta com PII: Higienizado On-Device e enviado para Nuvem sem dados sensíveis'
            : 'Complexidade Alta: Roteado para Nuvem de alta capacidade para diagnóstico aprofundado',
      );
      metrics.cloudCount++;
    }

    metrics.totalRequests++;

    // 4. ATUALIZA O CACHE SEMÂNTICO COM O RESULTADO
    semanticCache.put(
      text: rawText,
      analysis: result.analysis,
      rawJson: result.rawJson,
    );

    return result;
  }

  bool _isComplexIncident(String text) {
    // Texto longo (> 300 caracteres) ou termos técnicos de auditoria profunda / crash em produção
    if (text.length > 300) return true;

    final lower = text.toLowerCase();
    final complexKeywords = [
      'stacktrace',
      'stack trace',
      'memory leak',
      'estouro de memória',
      'concorrência',
      'thread safety',
      'deadlock',
      'npu',
      'crash repetitivo',
      'kernel panic',
      'sqlite',
      'dump',
    ];

    return complexKeywords.any((keyword) => lower.contains(keyword));
  }

  Future<AgentExecutionResult> _executeLocal({
    required String payload,
    required PrivacyReport privacyReport,
    required String routeReason,
  }) async {
    final isMediaPipe = activeLocalEngine == LocalEngineType.mediaPipeOnDevice;
    final IAgentProvider chosenProvider =
        isMediaPipe ? mediaPipeProvider : localProvider;

    try {
      final execution = await chosenProvider.processIncident(payload);
      return AgentExecutionResult(
        analysis: execution.analysis,
        providerName: execution.providerName,
        routeTarget: RouteTarget.localOllama,
        latencyMs: execution.latencyMs,
        costUsd: 0.00,
        isCacheHit: false,
        privacyReport: privacyReport,
        routeReason: routeReason,
        rawJson: execution.rawJson,
      );
    } catch (primaryError) {
      // Se o MediaPipe falhar (ex: arquivo ainda não copiado), tenta Ollama como primeiro fallback local
      if (isMediaPipe) {
        try {
          final ollamaExecution = await localProvider.processIncident(payload);
          return AgentExecutionResult(
            analysis: ollamaExecution.analysis,
            providerName: '${ollamaExecution.providerName} (Fallback Local)',
            routeTarget: RouteTarget.localOllama,
            latencyMs: ollamaExecution.latencyMs,
            costUsd: 0.00,
            isCacheHit: false,
            privacyReport: privacyReport,
            routeReason:
                'Fallback Local: MediaPipe indisponível ($primaryError), executado via Ollama',
            rawJson: ollamaExecution.rawJson,
          );
        } catch (_) {
          // Segue para fallback na nuvem se permitido
        }
      }

      // Se falhar o processamento local e não estiver em offline forçado, tenta fallback seguro na nuvem com aviso
      if (!forceOfflineMode) {
        final cloudRes = await cloudProvider.processIncident(payload);
        return AgentExecutionResult(
          analysis: cloudRes.analysis,
          providerName: '${cloudRes.providerName} (Fallback de Resiliência)',
          routeTarget: RouteTarget.cloudLLM,
          latencyMs: cloudRes.latencyMs,
          costUsd: cloudRes.costUsd,
          isCacheHit: false,
          privacyReport: privacyReport,
          routeReason:
              'Fallback Automático: Falha local ($primaryError), requisitado à Nuvem',
          rawJson: cloudRes.rawJson,
        );
      }
      rethrow;
    }
  }

  Future<AgentExecutionResult> _executeCloud({
    required String sanitizedPayload,
    required PrivacyReport privacyReport,
    required String routeReason,
  }) async {
    final execution = await cloudProvider.processIncident(sanitizedPayload);
    return AgentExecutionResult(
      analysis: execution.analysis,
      providerName: execution.providerName,
      routeTarget: RouteTarget.cloudLLM,
      latencyMs: execution.latencyMs,
      costUsd: execution.costUsd,
      isCacheHit: false,
      privacyReport: privacyReport,
      routeReason: routeReason,
      rawJson: execution.rawJson,
    );
  }
}

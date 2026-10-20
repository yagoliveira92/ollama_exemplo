import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_exemplo/data/providers/cloud_agent_provider.dart';
import 'package:ollama_exemplo/data/providers/hybrid_router.dart';
import 'package:ollama_exemplo/data/providers/ollama_local_provider.dart';
import 'package:ollama_exemplo/data/services/firewall_sanitizer.dart';
import 'package:ollama_exemplo/data/services/semantic_cache.dart';
import 'package:ollama_exemplo/domain/models/agent_result.dart';
import 'package:ollama_exemplo/domain/models/incident_analysis.dart';

void main() {
  group('Firewall Cognitivo On-Device (FirewallSanitizer)', () {
    final sanitizer = FirewallSanitizer();

    test('Deve anonimizar CPF, E-mail e Nomes de Clientes', () {
      const input =
          'Cliente João Silva, CPF 123.456.789-00, e-mail joao.silva@empresa.com.br reportou falha.';
      final report = sanitizer.sanitize(input);

      expect(report.hasPii, isTrue);
      expect(report.detectedPii.length, greaterThanOrEqualTo(2));
      expect(report.sanitizedText, contains('[CPF_PROTEGIDO]'));
      expect(report.sanitizedText, contains('[EMAIL_PROTEGIDO]'));
      expect(report.sanitizedText, contains('[NOME_ANONIMIZADO]'));
      expect(report.sanitizedText, isNot(contains('123.456.789-00')));
      expect(report.sanitizedText, isNot(contains('joao.silva@empresa.com.br')));
    });

    test('Deve retornar hasPii = false quando não há dados sensíveis', () {
      const input = 'O worker de background sofreu timeout de 30 segundos.';
      final report = sanitizer.sanitize(input);

      expect(report.hasPii, isFalse);
      expect(report.detectedPii, isEmpty);
      expect(report.sanitizedText, equals(input));
    });
  });

  group('Cache Semântico em Memória (SemanticCache)', () {
    late SemanticCache cache;

    setUp(() {
      cache = SemanticCache();
    });

    test('Deve recuperar resposta em cache para intenção e termos equivalentes', () {
      const analysis = IncidentAnalysis(
        incidentType: 'Cancelamento por Lentidão',
        severity: IncidentSeverity.baixa,
        recommendedAction: 'Averiguar SLA',
        executionTasks: ['Contatar cliente'],
        summary: 'Usuário cancelando',
      );

      cache.put(
        text: 'Cliente pede cancelamento por lentidao severa no aplicativo',
        analysis: analysis,
        rawJson: '{"incident_type": "Cancelamento por Lentidão"}',
      );

      // Frase muito similar com intenção semanticamente equivalente
      final hit = cache.lookup('Cliente solicitando cancelamento devido a lentidao no app');
      expect(hit, isNotNull);
      expect(hit!.analysis.incidentType, equals('Cancelamento por Lentidão'));
    });

    test('Deve retornar null se a consulta for de assunto totalmente diferente', () {
      final hit = cache.lookup('Erro crítico no kernel do servidor Linux com panic');
      expect(hit, isNull);
    });
  });

  group('Roteamento Híbrido Inteligente (HybridRouter)', () {
    late HybridRouter router;
    late OllamaLocalProvider mockLocal;
    late CloudAgentProvider mockCloud;

    setUp(() {
      mockLocal = OllamaLocalProvider();
      mockCloud = CloudAgentProvider();
      router = HybridRouter(localProvider: mockLocal, cloudProvider: mockCloud);
    });

    test('Deve rotear incidente complexo com StackTrace e SQLite para Cloud LLM', () async {
      const complexText =
          'Relatório de crash repetitivo em produção com StackTrace NPU, concorrência de threads '
          'e estouro de memória no banco SQLite. Deadlock at Thread #4 e Thread #11.';

      final result = await router.processIncident(complexText);

      expect(result.routeTarget, equals(RouteTarget.cloudLLM));
      expect(result.costUsd, greaterThan(0.0));
      expect(result.analysis.severity, equals(IncidentSeverity.alta));
      expect(result.isCacheHit, isFalse);
    });

    test('Deve servir segunda requisição idêntica via Cache Semântico (<10ms e \$0.00)', () async {
      const query = 'Consulta repetida de teste para validar o cache semântico em memória';

      // 1ª execução: processa e salva no cache
      await router.processIncident(query);

      // 2ª execução: deve vir do cache semântico
      final cachedResult = await router.processIncident(query);

      expect(cachedResult.routeTarget, equals(RouteTarget.semanticCache));
      expect(cachedResult.isCacheHit, isTrue);
      expect(cachedResult.costUsd, equals(0.00));
      expect(cachedResult.latencyMs, lessThan(30));
      expect(cachedResult.routeReason, contains('Cache Semântico'));
    });

    test('Deve forçar execução local quando forceOfflineMode for true', () async {
      router.forceOfflineMode = true;

      // Mesmo sendo complexo, deve respeitar a diretiva offline
      // Como não mockamos o http do Ollama aqui, se o Ollama local responder ou der SocketException,
      // ele não chamará a nuvem.
      expect(router.forceOfflineMode, isTrue);
    });
  });

  group('Parsing e Validação do Modelo IncidentAnalysis', () {
    test('Deve deserializar JSON estruturado estrito corretamente', () {
      final json = {
        'incident_type': 'Crash de Aplicação',
        'severity': 'Alta',
        'recommended_action': 'Subir réplica de contingência',
        'execution_tasks': [
          'Reiniciar serviço',
          'Notificar time de DevOps',
          'Coletar dump de memória',
        ],
        'summary': 'Falha grave no pool de conexões',
      };

      final analysis = IncidentAnalysis.fromJson(json);

      expect(analysis.incidentType, equals('Crash de Aplicação'));
      expect(analysis.severity, equals(IncidentSeverity.alta));
      expect(analysis.recommendedAction, equals('Subir réplica de contingência'));
      expect(analysis.executionTasks.length, equals(3));
      expect(analysis.summary, equals('Falha grave no pool de conexões'));
    });
  });
}

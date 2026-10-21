import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
// ignore: unused_import
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';

enum LlmEngineState {
  uninitialized,
  loading,
  ready,
  generating,
  error,
}

/// Serviço de integração com On-Device Edge AI utilizando o pacote oficial comunitário flutter_edge_ai.
class MediaPipeLlmService {
  LlmEngineState _state = LlmEngineState.uninitialized;
  InferenceModel? _activeModel;
  String? _loadedModelPath;
  String? _lastError;

  LlmEngineState get state => _state;
  bool get isReady => _state == LlmEngineState.ready && _activeModel != null;
  String? get loadedModelPath => _loadedModelPath;
  String? get lastError => _lastError;

  /// =========================================================================
  /// [WORKSHOP - PARTE 2] INICIALIZAÇÃO DO MODELO ON-DEVICE NA GPU/NPU
  /// =========================================================================
  /// Inicializa o modelo no dispositivo carregando os pesos na memória via flutter_edge_ai
  Future<bool> initialize({
    required String modelPath,
    int maxTokens = 512, // 512 tokens é ideal para dispositivos de entrada, reduzindo centenas de MB de RAM
    double temperature = 0.2,
    int topK = 40,
    int randomSeed = 0,
    ModelType? modelType,
    ModelFileType? fileType,
  }) async {
    _state = LlmEngineState.loading;
    _lastError = null;

    try {
      final file = File(modelPath);
      if (!await file.exists()) {
        _state = LlmEngineState.error;
        _lastError = 'Arquivo do modelo não encontrado em: $modelPath';
        return false;
      }

      // Detecção de tipo de arquivo e família do modelo
      // ignore: unused_local_variable
      final effectiveFileType = fileType ??
          (modelPath.toLowerCase().endsWith('.task')
              ? ModelFileType.task
              : ModelFileType.binary);

      final lowerPath = modelPath.toLowerCase();
      // ignore: unused_local_variable
      final effectiveModelType = modelType ??
          (lowerPath.contains('qwen')
              ? ModelType.qwen
              : lowerPath.contains('phi')
                  ? ModelType.phi
                  : ModelType.gemmaIt);

      // TODO: [WORKSHOP - PARTE 2.1] Registrar a engine nativa MediaPipe
      // Dica:
      // await FlutterEdgeAi.initialize(
      //   inferenceEngines: const [MediaPipeEngine()],
      // );

      // TODO: [WORKSHOP - PARTE 2.2] Registrar o arquivo do modelo no runtime
      // Dica:
      // await FlutterEdgeAi.installModel(
      //   modelType: effectiveModelType,
      //   fileType: effectiveFileType,
      // ).fromFile(file.path).install();

      // TODO: [WORKSHOP - PARTE 2.3] Carregar a instância do modelo ativo na GPU/NPU
      // Dica:
      // _activeModel = await FlutterEdgeAi.getActiveModel(maxTokens: maxTokens);

      _loadedModelPath = modelPath;
      _state = LlmEngineState.ready;
      return true;
    } catch (e) {
      _state = LlmEngineState.error;
      _lastError = 'Falha ao inicializar via flutter_edge_ai: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Verifica se o modelo já está carregado
  Future<bool> checkModelLoaded() async {
    return isReady;
  }

  /// =========================================================================
  /// [WORKSHOP - PARTE 2.4] EXECUÇÃO DA INFERÊNCIA NO DISPOSITIVO
  /// =========================================================================
  /// Gera a resposta completa do modelo a partir de um prompt
  Future<String> generateResponse(
    String prompt, {
    double temperature = 0.2,
    int topK = 40,
  }) async {
    if (!isReady || _activeModel == null) {
      throw StateError(
        'O modelo On-Device não está carregado. Estado: $_state. Erro: $_lastError',
      );
    }

    _state = LlmEngineState.generating;

    try {
      // TODO: [WORKSHOP - PARTE 2.4] Criar sessão de chat e gerar resposta
      // 1. Criar o chat no modelo ativo com temperature e topK:
      // final chat = await _activeModel!.createChat(
      //   temperature: temperature,
      //   topK: topK,
      // );
      //
      // 2. Enviar a mensagem com o prompt:
      // await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      //
      // 3. Aguardar a resposta:
      // final response = await chat.generateChatResponse();
      //
      // 4. Extrair o texto do token retornado:
      // final output = response is TextResponse ? response.token : response.toString();

      _state = LlmEngineState.ready;

      // Retorno temporário enquanto os alunos implementam o trecho acima
      return '{"incident_type": "Workshop", "severity": "Baixa", "recommended_action": "Complete o TODO 2.4", "execution_tasks": ["Completar código"], "summary": "Workshop TODO"}';
    } catch (e) {
      _state = LlmEngineState.ready;
      rethrow;
    }
  }

  /// Transmite tokens gerados em tempo real de forma assíncrona
  Stream<String> generateStream(
    String prompt, {
    double temperature = 0.2,
    int topK = 40,
  }) async* {
    if (!isReady || _activeModel == null) {
      throw StateError('O modelo não está carregado para streaming.');
    }

    _state = LlmEngineState.generating;

    try {
      final chat = await _activeModel!.createChat(
        temperature: temperature,
        topK: topK,
      );

      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      await for (final chunk in chat.generateChatResponseAsync()) {
        if (chunk is TextResponse) {
          yield chunk.token;
        } else {
          yield chunk.toString();
        }
      }
    } finally {
      _state = LlmEngineState.ready;
    }
  }

  /// Libera o modelo e a memória RAM/VRAM alocada
  Future<void> release() async {
    try {
      await _activeModel?.close();
      _activeModel = null;
      _loadedModelPath = null;
      _state = LlmEngineState.uninitialized;
    } catch (_) {}
  }
}

### Resumo dos 4 Pontos Preparados para o Workshop

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ [PARTE 1] ModelManagerService: Download do Modelo com Progresso                        │
│           lib/data/services/model_manager_service.dart                                 │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [PARTE 2] MediaPipeLlmService: Inicialização e Carregamento na GPU/NPU                 │
│           lib/data/services/mediapipe_llm_service.dart                                 │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [PARTE 3] MediaPipeOnDeviceProvider: Chat Templates do Gemma e Parse Estruturado       │
│           lib/data/providers/mediapipe_on_device_provider.dart                         │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [PARTE 4] HybridRouter: Roteamento Inteligente Híbrido e Firewall de Privacidade       │
│           lib/data/providers/hybrid_router.dart                                        │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### Detalhamento dos Arquivos e TODOs

#### 1. Download do Modelo via Rede
* **Arquivo:** [lib/data/services/model_manager_service.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/services/model_manager_service.dart#L139-L180)
* **Tag:** `// TODO: [WORKSHOP - PARTE 1.1]` no método [downloadModelWithProgress](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/services/model_manager_service.dart#L148)
* **O que os alunos fazem:**
  * Escrevem o download em streaming com `HttpClient`, gravando os chunks de bytes diretamente no disco do celular (`IOSink`).
  * Notificam o progresso percentual (`downloaded / total`) no callback `onProgress`.
* **Como testar visualmente:** No botão de configurações (engrenagem) do app, foi adicionado um card com campo de URL e barra de progresso em tempo real conectada a essa função.

---

#### 2. Inicialização na GPU/NPU via Edge AI
* **Arquivo:** [lib/data/services/mediapipe_llm_service.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/services/mediapipe_llm_service.dart#L28-L140)
* **Tags:**
  * `// TODO: [WORKSHOP - PARTE 2.1]`: Registrar a engine nativa [MediaPipeEngine](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/services/mediapipe_llm_service.dart#L60) com `FlutterEdgeAi.initialize()`.
  * `// TODO: [WORKSHOP - PARTE 2.2]`: Registrar o arquivo do modelo com `FlutterEdgeAi.installModel(...).fromFile().install()`.
  * `// TODO: [WORKSHOP - PARTE 2.3]`: Alocar a instância ativa na memória/NPU com `FlutterEdgeAi.getActiveModel(maxTokens: 512)`.
  * `// TODO: [WORKSHOP - PARTE 2.4]`: Criar a sessão de chat e disparar a geração de tokens via `chat.generateChatResponse()`.

---

#### 3. Chat Templates do Gemma e Parse do JSON
* **Arquivo:** [lib/data/providers/mediapipe_on_device_provider.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/providers/mediapipe_on_device_provider.dart#L50-L100)
* **Tags:**
  * `// TODO: [WORKSHOP - PARTE 3.1]`: Formatar o prompt no método [_buildGemmaPrompt](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/providers/mediapipe_on_device_provider.dart#L89) usando as tags oficiais do Gemma (`<start_of_turn>user` e `<end_of_turn><start_of_turn>model`) instruindo a saída estrita em JSON.
  * `// TODO: [WORKSHOP - PARTE 3.2]`: Chamar a geração, cronometrar a latência on-device e deserializar para o objeto de domínio [IncidentAnalysis](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/domain/models/incident_analysis.dart).

---

#### 4. Regras do Roteador Híbrido (Edge vs Cloud)
* **Arquivo:** [lib/data/providers/hybrid_router.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/providers/hybrid_router.dart#L87-L145)
* **Tags:**
  * `// TODO: [WORKSHOP - PARTE 4.1]`: Executar o firewall cognitivo local (`sanitizer.sanitize(rawText)`).
  * `// TODO: [WORKSHOP - PARTE 4.2]`: Estruturar a árvore de decisão:
    1. Se `forceOfflineMode` $\rightarrow$ Executa no Edge (resiliência).
    2. Se `hasSensitivePii` $\rightarrow$ Executa no Edge (privacidade/LGPD).
    3. Se não for complexo $\rightarrow$ Executa no Edge (custo zero).
    4. Se for complexo e online $\rightarrow$ Envia para a Nuvem com o payload sanitizado.

---

### Dica para o dia do Workshop
Se quiser criar uma branch específica para os alunos clonarem como ponto de partida (sem as implementações):
```bash
git checkout -b workshop-starter
```
E nesta branch (`on-device`), você mantém o **GABARITO COMPLETO FUNCIONAL** que já está pronto e testado.

---

## 📖 Gabarito Oficial de Código (Referência do Instrutor)

### Gabarito 1: Download de Modelo com Progresso em Streaming
**Arquivo:** [lib/data/services/model_manager_service.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/services/model_manager_service.dart)

```dart
Future<String> downloadModelWithProgress({
  required String downloadUrl,
  String filename = defaultGemmaModelName,
  void Function(double progress, int receivedBytes, int totalBytes)? onProgress,
}) async {
  final modelsDir = await getModelsDirectory();
  final destinationFile = File('${modelsDir.path}/$filename');
  final tempFile = File('${modelsDir.path}/$filename.part');

  final client = HttpClient()..autoUncompress = true;

  try {
    final uri = Uri.parse(downloadUrl);
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}', uri: uri);
    }

    final totalBytes = response.contentLength;
    int receivedBytes = 0;

    if (await tempFile.exists()) await tempFile.delete();
    final sink = tempFile.openWrite();

    await for (final chunk in response) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
      }
    }

    await sink.flush();
    await sink.close();

    if (await destinationFile.exists()) await destinationFile.delete();
    await tempFile.rename(destinationFile.path);

    return destinationFile.path;
  } finally {
    client.close();
  }
}
```

---

### Gabarito 2: Inicialização e Carregamento na GPU/NPU
**Arquivo:** [lib/data/services/mediapipe_llm_service.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/services/mediapipe_llm_service.dart)

```dart
// 1. Registro da engine
await FlutterEdgeAi.initialize(
  inferenceEngines: const [MediaPipeEngine()],
);

// 2. Instalação do modelo
await FlutterEdgeAi.installModel(
  modelType: effectiveModelType,
  fileType: effectiveFileType,
).fromFile(file.path).install();

// 3. Alocação na memória/GPU
_activeModel = await FlutterEdgeAi.getActiveModel(maxTokens: maxTokens);
```

E para a inferência:
```dart
final chat = await _activeModel!.createChat(
  temperature: temperature,
  topK: topK,
);

await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
final response = await chat.generateChatResponse();
final output = response is TextResponse ? response.token : response.toString();
```

---

### Gabarito 3: Chat Template do Gemma 2 e Parse JSON
**Arquivo:** [lib/data/providers/mediapipe_on_device_provider.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/providers/mediapipe_on_device_provider.dart)

```dart
String _buildGemmaPrompt(String incidentText) {
  return '''<start_of_turn>user
Você é um Engenheiro de Confiabilidade de Sistemas (SRE) especializado em triagem e diagnóstico de incidentes.
Analise o relatório e retorne EXCLUSIVAMENTE um objeto JSON válido (sem textos extras ou markdown) com as seguintes chaves:
- "incident_type": tipo da falha.
- "severity": criticidade ("Baixa", "Média", "Alta").
- "recommended_action": ação imediata em 1 parágrafo.
- "execution_tasks": lista com 3 a 5 passos práticos acionáveis.
- "summary": resumo técnico em 1 frase.

Incidente para análise:
$incidentText<end_of_turn>
<start_of_turn>model
''';
}
```

---

### Gabarito 4: Regras de Decisão do Roteador Híbrido
**Arquivo:** [lib/data/providers/hybrid_router.dart](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/data/providers/hybrid_router.dart)

```dart
if (forceOfflineMode) {
  // Regra 1: Offline forçado -> Direto para On-Device
  result = await _executeLocal(
    payload: sanitizedPayload,
    privacyReport: privacyReport,
    routeReason: 'Modo Offline Ativado: Resiliência 100% On-Device garantida',
  );
  metrics.localCount++;
  metrics.totalSavedUsd += cloudProvider.costPerRequest;
} else if (hasSensitivePii && !isComplex) {
  // Regra 2: Dados PII detectados -> Retido localmente (LGPD)
  result = await _executeLocal(
    payload: sanitizedPayload,
    privacyReport: privacyReport,
    routeReason: 'Firewall Cognitivo On-Device: PII retido localmente para privacidade',
  );
  metrics.localCount++;
  metrics.totalSavedUsd += cloudProvider.costPerRequest;
} else if (!isComplex) {
  // Regra 3: Trivial -> Edge AI (\$0.00 custo e velocidade)
  result = await _executeLocal(
    payload: sanitizedPayload,
    privacyReport: privacyReport,
    routeReason: 'Complexidade Baixa (<300 chars): Roteado para Edge AI (\$0.00 de custo)',
  );
  metrics.localCount++;
  metrics.totalSavedUsd += cloudProvider.costPerRequest;
} else {
  // Regra 4: Complexo com rede -> Nuvem (apenas payload previamente sanitizado)
  result = await _executeCloud(
    sanitizedPayload: sanitizedPayload,
    privacyReport: privacyReport,
    routeReason: hasSensitivePii
        ? 'Complexidade Alta com PII: Higienizado On-Device e enviado para Nuvem'
        : 'Complexidade Alta: Roteado para Nuvem de alta capacidade',
  );
  metrics.cloudCount++;
}
```
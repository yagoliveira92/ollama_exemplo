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
Se quiser criar uma branch específica para os alunos clonarem como ponto de partida:
```bash
git checkout -b workshop-starter
git add .
git commit -m "chore: scaffold workshop starter with TODO challenges"
```
E quando precisar mostrar a solução pronta em tempo real, basta alternar para a branch `on-device-complete`.
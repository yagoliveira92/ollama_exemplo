### O que é este aplicativo? (Visão Geral Descomplicada)

O **EdgeInspector** é um aplicativo que simula um cenário corporativo real: **triagem automatizada de chamados de suporte técnico e incidentes de TI**. 

Quando um usuário envia uma reclamação ou um log de erro do sistema cheio de linhas técnicas e dados pessoais (CPF, e-mail), uma IA precisa ler esse texto caótico e transformá-lo em um relatório técnico estruturado (com criticidade, ação imediata e checklist de tarefas).

#### Onde entra a Edge AI?
Em vez de simplesmente mandar tudo para a nuvem (OpenAI, Claude, etc.), o app demonstra uma **Arquitetura de IA Híbrida em 3 camadas**:
1. **Cache Semântico Local:** Se alguém já relatou um problema similar, responde em menos de 10 milissegundos sem gastar bateria nem rede.
2. **Firewall Cognitivo On-Device:** O celular identifica e mascara dados pessoais (LGPD/PII) **antes** que qualquer coisa saia do aparelho.
3. **Roteador Inteligente (Orquestrador Híbrido):** 
   - Se a tarefa for simples ou exigir privacidade estrita $\rightarrow$ processa no próprio aparelho (**Edge AI On-Device** com Gemma 2B ou Ollama).
   - Se for um problema técnico hipercomplexo que exige raciocínio profundo $\rightarrow$ envia para a **Nuvem**, mas com os dados já higienizados pelo celular.

---

### Entendendo as Telas e as Entradas (O que cada botão faz)

A tela principal possui 4 áreas fundamentais:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Barra de Infraestrutura e Métricas Acumuladas (Header)   │
├─────────────────────────────────────────────────────────────┤
│ 2. Painel de Entrada de Texto + 3 Presets de Demonstração   │
├─────────────────────────────────────────────────────────────┤
│ 3. Telemetria da Decisão (Quem processou? Por quê? Custo?)  │
├─────────────────────────────────────────────────────────────┤
│ 4. Firewall de Privacidade (Diff) e Relatório Estruturado   │
└─────────────────────────────────────────────────────────────┘
```

#### 1. Os 3 Exemplos Prontos (Presets)
Estes três botões em formato de chip foram desenhados propositalmente para guiar o seu roteiro de demonstração:

* **Exemplo 1: Simples + PII (Cliente com CPF)**
  * **O que envia:** *"Cliente João Silva, CPF 123.456.789-00, e-mail joao.silva@empresa.com.br, solicita cancelamento..."*
  * **O que demonstra:** O **Firewall Cognitivo**. Como o texto tem dados sensíveis e é curto (< 300 caracteres), o roteador decide processar **100% no Edge (Local)** para não vazar dados para a rede pública, gerando custo zero (\$0.00).
* **Exemplo 2: Complexo / Longo (Crash em Produção com StackTrace)**
  * **O que envia:** Um relatório de pane com concorrência de threads, deadlock e estouro de memória no SQLite.
  * **O que demonstra:** A **Nuvem Híbrida**. Como o problema é longo e complexo (> 300 caracteres com termos críticos), o roteador entende que um modelo pequeno de Edge não teria raciocínio suficiente e despacha para a **Nuvem** (simulando latência de rede e custo de API).
* **Exemplo 3: Pergunta Repetida (Cache Semântico)**
  * **O que envia:** Exatamente o mesmo texto do Exemplo 1.
  * **O que demonstra:** O **Cache Semântico**. Ao clicar neste botão logo após o Exemplo 1, a resposta surge de forma instantânea (**< 10ms**). Você mostra aos alunos que a aplicação não precisou nem ligar a GPU/NPU do celular: resolveu via busca vetorial/tokens em memória.

#### 2. Os Controles de Infraestrutura (No topo da tela)
* **Switch "Simular Queda de Nuvem" (Modo Offline Forçado):**
  * Se você ligar essa chave, mesmo que você clique no *Exemplo 2 (Complexo)*, o roteador é proibido de usar a nuvem e executa tudo localmente no Edge. Isso demonstra **resiliência operacional** (o app funciona num avião ou subsolo sem internet).
* **Botão de Ajustes (Ícone de Engrenagem / Sliders):**
  * Permite alternar a engine local entre:
    1. **Flutter Edge AI (MediaPipe + Gemma 2B):** Modelo empacotado direto no app rodando na NPU/GPU do celular.
    2. **Ollama Local:** Conecta a um servidor Ollama rodando no seu computador (via Wi-Fi/localhost), útil para testar modelos como `gemma2:2b` ou `gemma4:e4b-mlx`.

---

### O que o App gera como Resultado?

Após clicar em **"Processar com Roteamento Híbrido"**, aparecem 3 cartões:

1. [TelemetryCard](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/presentation/widgets/telemetry_card.dart#L5):
   * Mostra qual motor foi acionado (⚡ *Cache*, 🖥️ *Ollama/Gemma Edge*, ou ☁️ *Nuvem*).
   * Mostra a **Latência** (ms) e o **Custo Financeiro** (\$0.00 vs \$0.0024).
   * Mostra a **Justificativa da Decisão** tomada pelo roteador.
2. [PrivacyDiffViewer](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/presentation/widgets/privacy_diff_viewer.dart#L5):
   * Possui duas abas: *Texto Bruto* vs *Texto Sanitizado*.
   * Mostra os badges com os dados capturados: `Nome Pessoal`, `Documento CPF`, `Endereço E-mail`.
3. [StructuredIncidentCard](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/presentation/widgets/structured_incident_card.dart#L6):
   * O resultado estruturado: Tipo de Incidente, Nível de Severidade (Baixa/Média/Alta), Ação Recomendada e um checklist interativo com tarefas de correção.
   * Permite abrir o **JSON Bruto** para mostrar aos alunos como a IA devolveu a estrutura pronta para uma API backend consumir.

---

### Roteiro Didático para sua Palestra (Storytelling em 4 Atos)

Para prender a atenção dos alunos e evitar confusão, siga esta ordem cronológica de demonstração:

#### Ato 1: O Problema das IAs "100% Nuvem" (Contextualização)
> *"Pessoal, por que não mandamos tudo para a OpenAI ou Google Cloud em produção? Por 3 motivos: **Latência**, **Custo financeiro em escala** e **Vazamento de Privacidade (LGPD)**."*

#### Ato 2: O Firewall Cognitivo e a Privacidade (Demonstração do Exemplo 1)
1. Clique no botão **`Exemplo 1: Simples + PII`**.
2. Aponte para o texto com CPF e e-mail no campo de entrada.
3. Clique em **"Processar com Roteamento Híbrido"**.
4. **O que destacar aos alunos:**
   * Olhem no [PrivacyDiffViewer](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/presentation/widgets/privacy_diff_viewer.dart#L5): O CPF virou `[CPF_PROTEGIDO]`.
   * Olhem na [TelemetryCard](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/presentation/widgets/telemetry_card.dart#L5): Foi executado **On-Device (Edge)**. Nenhum dado de CPF saiu deste aparelho. O custo foi de **\$0.0000**.

#### Ato 3: O Cérebro Especialista na Nuvem (Demonstração do Exemplo 2)
1. Clique no botão **`Exemplo 2: Complexo / Longo`**.
2. Clique em **"Processar"**.
3. **O que destacar aos alunos:**
   * O Edge AI do celular tem limites de tamanho (geralmente modelos de 2B a 4B parâmetros). Um erro de deadlock em C++ exige um modelo maior.
   * O Roteador percebeu a complexidade e mandou para a **Nuvem**.
   * Mostre o tempo de resposta (~1000ms a 1400ms) e o custo de **\$0.0024 USD** gerado.

#### Ato 4: A Inteligência de Economia (Demonstração do Exemplo 3)
1. Clique no botão **`Exemplo 3: Pergunta Repetida`**.
2. Clique em **"Processar"**.
3. **O que destacar aos alunos:**
   * A resposta foi praticamente instantânea (**~3ms**).
   * Mostre a [HeaderMetricsBar](file:///Users/yagoliveira92/Documents/App/ollama_exemplo/lib/presentation/widgets/header_metrics_bar.dart#L5) no topo: o contador de requisições subiu, a economia de dólares acumulou e nenhuma bateria foi desperdiçada reprocessando a mesma coisa.

#### Ato 5: Resiliência em Falhas (Demonstração do Switch Offline)
1. Ative a chave **"Simular Queda de Nuvem"**.
2. Selecione o **Exemplo 2** (que iria para a nuvem) e clique em **"Processar"**.
3. **O que destacar aos alunos:**
   * O sistema não quebrou nem deu tela de "Sem conexão com a internet". O Edge assumiu a carga de trabalho no próprio hardware.

---

### Metáfora para fixar com os alunos

> *"Pensem no **Edge AI** como o **Clínico Geral no Posto de Saúde**: ele atende rápido, resolve dores de cabeça simples, não cobra caro e cuida da sua triagem imediata.  
> Já a **IA na Nuvem** é o **Hospital com Cirurgiões Especialistas**: você só aciona quando o caso é crítico e exige alta complexidade, sem sobrecarregá-lo com coisas corriqueiras."*
# EdgeInspector — Sanitizador e Extrator de Logs

**EdgeAI On-Device • Arquitetura Híbrida • Privacidade por Padrão**

Sistema completo para ingestão, higienização e estruturação inteligente de logs e incidentes de TI — tudo executado localmente no dispositivo com Ollama (Llama 4:E4B-MLX).

## 🚀 Principais Funcionalidades

### 🔐 Firewall Cognitivo On-Device
- Detecção e remoção automática de informações de identificação pessoal (PII)
- Sanitização de e-mails, telefones, CPFs, números de cartão, tokens e senhas
- Política de retenção inteligente: apenas logs **não sensíveis** saem do dispositivo

### 🧠 Roteamento Inteligente com IA Híbrida
- **Cache Semântico em Memória:** respostas instantâneas (<10ms) para incidentes recorrentes
- **Ollama Local (EdgeAI):** análise de logs simples e sem dados pessoais
- **Cloud High-Performance:** logs complexos com PII (após sanitização) recebem diagnóstico completo na nuvem

### 📉 Telemetria e Otimização de Custos
- Monitoramento em tempo real de economia de custos com processamento local
- Métricas de latência e precisão de inferência
- Comparativo automático de desempenho entre EdgeAI e Cloud

### ✨ Interface Moderna (Design System Corporativo)
- **Tema Premium:** branco (#FFFFFF), cinza (#F8F9FA), verde esmeralda (#00A884) e grafite (#3D3D3D)
- **Widgets Avançados:** gráficos com animação, scroll infinito, layout responsivo
- **Modo Offline:** operação 100% local garantida

---

## 🛠️ Instalação e Configuração

### 1. Pré-requisitos
- macOS 13+ com Apple Silicon (M1/M2/M3/M4)
- Flutter SDK 3.28.0+ (stable)
- [Ollama](https://ollama.com) instalado e rodando

### 2. Configurar o Ollama
Abra o terminal e instale o modelo Llama 4:E4B-MLX:
```bash
ollama pull gemma4:e4b-mlx
```

### 3. Dependências Flutter
Adicione estas dependências ao `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
```

### 4. Executar o App
```bash
flutter run
```

---

## 📂 Arquitetura do Projeto

```
lib/
├── domain/                  # Contratos e modelos puros
│   └── contracts/
│       └── i_agent_provider.dart
│
├── data/                    # Implementações e serviços de IA
│   ├── providers/
│   │   ├── hybrid_router.dart          # Orquestrador híbrido
│   │   ├── ollama_local_provider.dart  # EdgeAI local
│   │   └── cloud_agent_provider.dart   # API REST Cloud
│   └── services/
│       ├── firewall_sanitizer.dart     # Higienização de dados
│       └── semantic_cache.dart         # Cache baseado em similaridade
│
├── presentation/            # Interface do usuário
│   ├── screens/
│   │   └── edge_inspector_screen.dart
│   ├── theme/app_theme.dart            # Design system corporativo
│   └── widgets/
│       ├── header_metrics_bar.dart     # Métricas em tempo real
│       ├── incident_history.dart       # Histórico de logs
│       ├── structured_incident_card.dart # Card de resultados
│       └── telemetry_card.dart         # Análise de performance
│
└── main.dart                # Entry point da aplicação
```

---

## 📋 Telas Principais

### Tela Principal
Interface central com:
1. Barra superior com métricas de custo e latência
2. Campo de texto para inserir logs
3. Botão de análise com feedback visual do roteamento
4. Histórico de processamento com scroll infinito
5. Configuração de modo offline

### Tela de Histórico
- Lista scrollável de todos os incidentes processados
- Indicadores visuais para:
  - ⚡ Cache hit (verde)
  - 🏠 Local (azul)
  - ☁️ Cloud (roxo)
- Card detalhado por incidente com:
  - Texto original vs sanitizado
  - Análise estruturada da IA
  - Motivo do roteamento

### Tela de Telemetria
- Gráficos animados de desempenho
- Custo total economizado (US$)
- Latência média por tipo de processamento
- Detalhes da precisão do cache semântico
- Comparativo Edge vs Cloud

---

## 🤖 Lógica de Roteamento

1. **Cache Semântico:** verificações <10ms antes de qualquer processamento
2. **PII Detection:** Firewall Cognitivo bloqueia dados sensíveis na origem
3. **Offline Mode:** operação 100% local garantida
4. **Complexidade Moderada:** incidentes curtos (<300 chars) sem PII vão para Ollama Local
5. **Complexidade Alta:** logs longos ou técnicos são enviados para Cloud após sanitização

---

## 📊 Métricas de Performance

| Cenário | Custo | Latência | Rota | Proteção
|---------|-------|----------|------|----------
| Cache Hit | $0.00 | <10ms | Cache | ✅ Máxima
| Local | $0.00 | 150-300ms | Ollama | ✅ PII bloqueado
| Cloud | Variável | 500-1200ms | API | ✅ Sanitizado

---

## ⚠️ Considerações Importantes

### Performance no macOS
- Apple Silicon M1/M2/M3/M4 é obrigatório para inferência local eficiente
- Modelos maiores (>1B params) exigem mais RAM (16GB+ recomendado)
- Cache semântico mantém precisão alta com <512MB de memória

### Limitações do Ollama
- Versão atual pode ter latência inicial na primeira inferência
- Modelos otimizados (E4B) são ideais para dispositivos Apple
- Produção enterprise pode necessitar quantização para modelos <1B

---

## 🚀 Próximos Passos Recomendados

1. **Quantização:** adicionar `ollama_agent_provider.dart` com modelos quantizados (2-bit)
2. **Detecção de Padrões:** regex aprimorado para tokens de PII específicos do cliente
3. **Persistência:** salvar cache em Room/Realm para persistência entre sessões
4. **Análise Preditiva:** prever custos futuros com base em padrões históricos

---

**EdgeInspector** • IA Híbrida para EdgeAI • Privacy by Default

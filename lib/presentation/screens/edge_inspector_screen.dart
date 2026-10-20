import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/providers/cloud_agent_provider.dart';
import '../../data/providers/hybrid_router.dart';
import '../../data/providers/ollama_local_provider.dart';
import '../../domain/models/agent_result.dart';
import '../theme/app_theme.dart';
import '../widgets/header_metrics_bar.dart';
import '../widgets/input_panel.dart';
import '../widgets/ollama_settings_dialog.dart';
import '../widgets/privacy_diff_viewer.dart';
import '../widgets/structured_incident_card.dart';
import '../widgets/telemetry_card.dart';

class EdgeInspectorScreen extends StatefulWidget {
  final HybridRouter? router;

  const EdgeInspectorScreen({super.key, this.router});

  @override
  State<EdgeInspectorScreen> createState() => _EdgeInspectorScreenState();
}

class _EdgeInspectorScreenState extends State<EdgeInspectorScreen> {
  late final HybridRouter _router;
  late final TextEditingController _inputController;

  bool _isProcessing = false;
  bool _isPinging = false;
  bool? _isOllamaOnline;
  AgentExecutionResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();

    // Inicialização da Arquitetura com Inversão de Controle
    final local = OllamaLocalProvider();
    final cloud = CloudAgentProvider();
    _router = widget.router ?? HybridRouter(localProvider: local, cloudProvider: cloud);

    // Carrega preset inicial para facilitar teste imediato
    _inputController.text = InputPanel.presets.first.text;

    // Ping inicial de verificação no daemon do Ollama
    _pingOllama();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _pingOllama() async {
    setState(() => _isPinging = true);
    final isOnline = await _router.localProvider.ping();
    if (mounted) {
      setState(() {
        _isPinging = false;
        _isOllamaOnline = isOnline;
      });
    }
  }

  Future<void> _processIncident() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe ou cole um relatório de incidente para análise.'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _router.processIncident(text);
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(e);
      }
    }
  }

  void _showErrorDialog(dynamic error) {
    String message = error.toString();
    bool isOllamaError = error is SocketException ||
        message.contains('11434') ||
        message.contains('Ollama') ||
        message.contains('Connection refused');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Row(
          children: [
            Icon(
              isOllamaError ? Icons.warning_amber_rounded : Icons.error_outline,
              color: const Color(0xFFC62828),
            ),
            const SizedBox(width: 8),
            const Text(
              'Atenção na Execução',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGraphite,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.darkGraphite),
            ),
            if (isOllamaError) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como inicializar o modelo local no terminal:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGraphite,
                      ),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      'ollama run gemma4:e4b-mlx\n# ou se preferir:\nollama run gemma2:2b',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppTheme.darkGraphite)),
          ),
          if (isOllamaError)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openSettings();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald),
              child: const Text('Ajustar URL/Modelo'),
            ),
        ],
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (ctx) => OllamaSettingsDialog(
        localProvider: _router.localProvider,
        onSaved: () {
          setState(() {});
          _pingOllama();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSurface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, size: 20, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EdgeInspector',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Sanitizador & Extrator Estruturado de Logs (Hybrid Edge AI)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações de IA',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderSubtle),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header com Indicador de Conexão e Custo Acumulado
                  HeaderMetricsBar(
                    metrics: _router.metrics,
                    isOfflineForced: _router.forceOfflineMode,
                    onToggleOffline: (val) {
                      setState(() {
                        _router.forceOfflineMode = val;
                      });
                    },
                    isOllamaOnline: _isOllamaOnline,
                    isPinging: _isPinging,
                    onPingOllama: _pingOllama,
                    onOpenSettings: _openSettings,
                  ),
                  const SizedBox(height: 16),

                  // 2. Painel de Entrada e Ações Rápidas
                  InputPanel(
                    controller: _inputController,
                    isProcessing: _isProcessing,
                    onProcess: _processIncident,
                    onSelectPreset: (text) {
                      setState(() {
                        _inputController.text = text;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Card de Telemetria e Resultados (quando disponível)
                  if (_lastResult != null) ...[
                    TelemetryCard(result: _lastResult!),
                    const SizedBox(height: 16),
                    PrivacyDiffViewer(privacyReport: _lastResult!.privacyReport),
                    const SizedBox(height: 16),
                    StructuredIncidentCard(
                      analysis: _lastResult!.analysis,
                      rawJson: _lastResult!.rawJson,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Estado Vazio Instrucional
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 48,
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Pronto para Análise de Incidentes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGraphite,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Escolha um dos exemplos acima ou cole um chamado técnico para testar o '
                            'Firewall Cognitivo On-Device, o Roteador Híbrido e o Cache Semântico.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IncidentPreset {
  final String label;
  final String description;
  final String text;
  final IconData icon;

  const IncidentPreset({
    required this.label,
    required this.description,
    required this.text,
    required this.icon,
  });
}

class InputPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isProcessing;
  final VoidCallback onProcess;
  final ValueChanged<String> onSelectPreset;

  const InputPanel({
    super.key,
    required this.controller,
    required this.isProcessing,
    required this.onProcess,
    required this.onSelectPreset,
  });

  static const List<IncidentPreset> presets = [
    IncidentPreset(
      label: 'Exemplo 1: Simples + PII',
      description: 'Cliente com CPF requisitando cancelamento por lentidão',
      icon: Icons.shield_outlined,
      text:
          'Cliente João Silva, CPF 123.456.789-00, e-mail joao.silva@empresa.com.br, '
          'solicita cancelamento imediato do plano Pro por lentidão crônica no app mobile.',
    ),
    IncidentPreset(
      label: 'Exemplo 2: Complexo / Longo',
      description: 'Crash repetitivo em produção com StackTrace NPU e concorrência',
      icon: Icons.bug_report_outlined,
      text:
          'Relatório de crash repetitivo em produção com StackTrace NPU, concorrência de threads '
          'e estouro de memória no banco SQLite. Exception at WorkerPool.cpp:322: '
          'Deadlock detectado entre Thread #4 (NPU Inference Task) e Thread #11 (SQLite WAL checkpoint). '
          'Ocorrências reportadas: 412 instâncias nas últimas 2 horas no cluster us-east-1.',
    ),
    IncidentPreset(
      label: 'Exemplo 3: Pergunta Repetida',
      description: 'Demonstrar Cache Semântico com resposta instantânea (<10ms)',
      icon: Icons.bolt_outlined,
      text:
          'Cliente João Silva, CPF 123.456.789-00, e-mail joao.silva@empresa.com.br, '
          'solicita cancelamento imediato do plano Pro por lentidão crônica no app mobile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, size: 18, color: AppTheme.darkGraphite),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Entrada de Incidente / Log Técnico',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGraphite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (controller.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: isProcessing ? null : () => controller.clear(),
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Campo de texto para colar o log bruto
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 3,
            enabled: !isProcessing,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppTheme.darkGraphite,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Cole aqui o log do sistema, relatório de chamado técnico, falha ou dados de suporte...',
              filled: true,
              fillColor: AppTheme.backgroundSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Presets de teste rápido
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              return ActionChip(
                avatar: Icon(preset.icon, size: 14, color: AppTheme.darkGraphite),
                label: Text(
                  preset.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGraphite,
                  ),
                ),
                backgroundColor: AppTheme.backgroundSurface,
                side: const BorderSide(color: AppTheme.borderSubtle),
                tooltip: preset.description,
                onPressed: isProcessing ? null : () => onSelectPreset(preset.text),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Botão de Ação Principal
          ElevatedButton.icon(
            onPressed: isProcessing ? null : onProcess,
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.alt_route, size: 18),
            label: Text(
              isProcessing
                  ? 'Processando com IA Híbrida...'
                  : 'Processar com Roteamento Híbrido',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

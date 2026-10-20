import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/incident_analysis.dart';
import '../theme/app_theme.dart';

class StructuredIncidentCard extends StatefulWidget {
  final IncidentAnalysis analysis;
  final String rawJson;

  const StructuredIncidentCard({
    super.key,
    required this.analysis,
    required this.rawJson,
  });

  @override
  State<StructuredIncidentCard> createState() => _StructuredIncidentCardState();
}

class _StructuredIncidentCardState extends State<StructuredIncidentCard> {
  final Set<int> _completedTasks = {};
  bool _showRawJson = false;

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIPO DE INCIDENTE DETECTADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.incidentType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGraphite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildSeverityBadge(analysis.severity),
            ],
          ),
          if (analysis.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              analysis.summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.darkGraphite,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Ação Recomendada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.primaryEmerald),
                    SizedBox(width: 6),
                    Text(
                      'AÇÃO RECOMENDADA IMEDIATA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGraphite,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  analysis.recommendedAction,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.darkGraphite,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Checklist de Tarefas Operacionais
          Row(
            children: [
              const Icon(Icons.checklist, size: 16, color: AppTheme.darkGraphite),
              const SizedBox(width: 6),
              const Text(
                'TAREFAS A EXECUTAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGraphite,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_completedTasks.length}/${analysis.executionTasks.length} concluídas',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...analysis.executionTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final isDone = _completedTasks.contains(index);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isDone) {
                    _completedTasks.remove(index);
                  } else {
                    _completedTasks.add(index);
                  }
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isDone ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 18,
                      color: isDone ? AppTheme.primaryEmerald : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDone ? AppTheme.textMuted : AppTheme.darkGraphite,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 10),
          // Toggle para ver JSON Bruto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showRawJson = !_showRawJson),
                icon: Icon(
                  _showRawJson ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: AppTheme.darkGraphite,
                ),
                label: Text(
                  _showRawJson ? 'Ocultar JSON Bruto' : 'Inspecionar JSON Estrito',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGraphite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
              if (_showRawJson)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: AppTheme.darkGraphite),
                  tooltip: 'Copiar JSON',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.rawJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('JSON copiado para a área de transferência'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (_showRawJson) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  widget.rawJson,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF80CBC4),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(IncidentSeverity severity) {
    Color bg;
    Color text;
    String label;

    switch (severity) {
      case IncidentSeverity.baixa:
        bg = AppTheme.severityLowBg;
        text = AppTheme.severityLowText;
        label = 'CRITICIDADE: BAIXA';
        break;
      case IncidentSeverity.media:
        bg = AppTheme.severityMediumBg;
        text = AppTheme.severityMediumText;
        label = 'CRITICIDADE: MÉDIA';
        break;
      case IncidentSeverity.alta:
        bg = AppTheme.severityHighBg;
        text = AppTheme.severityHighText;
        label = 'CRITICIDADE: ALTA';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

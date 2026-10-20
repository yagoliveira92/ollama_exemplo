import 'package:flutter/material.dart';
import '../../domain/models/agent_result.dart';
import '../theme/app_theme.dart';

class TelemetryCard extends StatelessWidget {
  final AgentExecutionResult result;

  const TelemetryCard({super.key, required this.result});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 500;
              final headerTitle = const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, size: 18, color: AppTheme.darkGraphite),
                  SizedBox(width: 8),
                  Text(
                    'Telemetria da Execução Híbrida',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGraphite,
                    ),
                  ),
                ],
              );

              final badge = _buildRouteBadge();

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerTitle,
                    const SizedBox(height: 8),
                    badge,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: headerTitle),
                  const SizedBox(width: 8),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Métricas de Latência e Custo
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Latência do Processamento',
                  value: '${result.latencyMs} ms',
                  icon: Icons.timer_outlined,
                  color: result.latencyMs < 50
                      ? AppTheme.primaryEmerald
                      : result.latencyMs < 1000
                          ? AppTheme.darkGraphite
                          : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Custo Financeiro da Operação',
                  value: result.costUsd == 0.0
                      ? '\$0.0000 (100% On-Device)'
                      : '\$${result.costUsd.toStringAsFixed(4)} USD',
                  icon: Icons.attach_money_outlined,
                  color: result.costUsd == 0.0 ? AppTheme.primaryEmerald : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Motivo da decisão do HybridRouter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 15, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.routeReason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGraphite,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteBadge() {
    Color bg;
    Color text;
    IconData icon;
    String label;

    switch (result.routeTarget) {
      case RouteTarget.localOllama:
        bg = AppTheme.localBadgeBg;
        text = AppTheme.localBadgeText;
        icon = Icons.memory;
        label = result.providerName;
        break;
      case RouteTarget.cloudLLM:
        bg = AppTheme.cloudBadgeBg;
        text = AppTheme.cloudBadgeText;
        icon = Icons.cloud_outlined;
        label = result.providerName;
        break;
      case RouteTarget.semanticCache:
        bg = AppTheme.cacheBadgeBg;
        text = AppTheme.cacheBadgeText;
        icon = Icons.bolt;
        label = 'Cache Semântico (Hit)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: text,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

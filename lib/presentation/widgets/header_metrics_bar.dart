import 'package:flutter/material.dart';
import '../../data/providers/hybrid_router.dart';
import '../theme/app_theme.dart';

class HeaderMetricsBar extends StatelessWidget {
  final CumulativeMetrics metrics;
  final bool isOfflineForced;
  final ValueChanged<bool> onToggleOffline;
  final bool? isOllamaOnline;
  final bool isPinging;
  final LocalEngineType activeEngine;
  final VoidCallback onPingOllama;
  final VoidCallback onOpenSettings;

  const HeaderMetricsBar({
    super.key,
    required this.metrics,
    required this.isOfflineForced,
    required this.onToggleOffline,
    required this.isOllamaOnline,
    required this.isPinging,
    this.activeEngine = LocalEngineType.mediaPipeOnDevice,
    required this.onPingOllama,
    required this.onOpenSettings,
  });

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
          // Barra de status de infraestrutura e controles rápidos
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 430;
              final statusWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador Ollama Daemon
                  InkWell(
                    onTap: isPinging ? null : onPingOllama,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusBorderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPinging)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _statusTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.refresh, size: 14, color: _statusTextColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão de Ajustes
                  IconButton(
                    icon: const Icon(Icons.tune, size: 18, color: AppTheme.darkGraphite),
                    onPressed: onOpenSettings,
                    tooltip: 'Configurar Endpoint e Modelo do Ollama',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              );

              final switchWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Simular Queda de Nuvem',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOfflineForced ? AppTheme.primaryDark : AppTheme.darkGraphite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isOfflineForced,
                      activeThumbColor: AppTheme.primaryEmerald,
                      onChanged: onToggleOffline,
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusWidget,
                    const SizedBox(height: 8),
                    switchWidget,
                  ],
                );
              }

              return Row(
                children: [
                  statusWidget,
                  const Spacer(),
                  switchWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 14),
          // Métricas Financeiras e Latência Acumulada
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 450;
              if (isCompact) {
                return Column(
                  children: [
                    _buildMetricItem(
                      icon: Icons.savings_outlined,
                      label: 'Economia Acumulada',
                      value: '\$${metrics.totalSavedUsd.toStringAsFixed(4)} USD',
                      highlightColor: AppTheme.primaryEmerald,
                      subtext: '${metrics.localCount + metrics.cacheCount} reqs sem custo de nuvem',
                    ),
                    const Divider(height: 16, color: AppTheme.borderSubtle),
                    _buildMetricItem(
                      icon: Icons.speed_outlined,
                      label: 'Latência Economizada',
                      value: '${(metrics.totalLatencySavedMs / 1000).toStringAsFixed(2)}s',
                      highlightColor: AppTheme.darkGraphite,
                      subtext: '${metrics.cacheCount} hits em cache (<10ms)',
                    ),
                    const Divider(height: 16, color: AppTheme.borderSubtle),
                    _buildMetricItem(
                      icon: Icons.pie_chart_outline,
                      label: 'Total de Requisições',
                      value: '${metrics.totalRequests}',
                      highlightColor: AppTheme.darkGraphite,
                      subtext: 'Local: ${metrics.localCount} | Cloud: ${metrics.cloudCount}',
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.savings_outlined,
                      label: 'Economia Acumulada',
                      value: '\$${metrics.totalSavedUsd.toStringAsFixed(4)} USD',
                      highlightColor: AppTheme.primaryEmerald,
                      subtext: '${metrics.localCount + metrics.cacheCount} reqs sem custo de nuvem',
                    ),
                  ),
                  Container(width: 1, height: 42, color: AppTheme.borderSubtle),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.speed_outlined,
                      label: 'Latência Economizada',
                      value: '${(metrics.totalLatencySavedMs / 1000).toStringAsFixed(2)}s',
                      highlightColor: AppTheme.darkGraphite,
                      subtext: '${metrics.cacheCount} hits em cache (<10ms)',
                    ),
                  ),
                  Container(width: 1, height: 42, color: AppTheme.borderSubtle),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.pie_chart_outline,
                      label: 'Total de Requisições',
                      value: '${metrics.totalRequests}',
                      highlightColor: AppTheme.darkGraphite,
                      subtext: 'Local: ${metrics.localCount} | Cloud: ${metrics.cloudCount}',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color highlightColor,
    required String subtext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: highlightColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color get _statusBgColor {
    if (activeEngine == LocalEngineType.mediaPipeOnDevice) {
      return const Color(0xFFE0F2F1); // Teal suave
    }
    if (isOllamaOnline == true) return const Color(0xFFE8F5E9);
    if (isOllamaOnline == false) return const Color(0xFFFFEBEE);
    return const Color(0xFFF5F5F5);
  }

  Color get _statusBorderColor {
    if (activeEngine == LocalEngineType.mediaPipeOnDevice) {
      return AppTheme.primaryEmerald;
    }
    if (isOllamaOnline == true) return const Color(0xFFC8E6C9);
    if (isOllamaOnline == false) return const Color(0xFFFFCDD2);
    return AppTheme.borderSubtle;
  }

  Color get _statusDotColor {
    if (activeEngine == LocalEngineType.mediaPipeOnDevice) {
      return AppTheme.primaryEmerald;
    }
    if (isOllamaOnline == true) return const Color(0xFF43A047);
    if (isOllamaOnline == false) return const Color(0xFFE53935);
    return Colors.grey;
  }

  Color get _statusTextColor {
    if (activeEngine == LocalEngineType.mediaPipeOnDevice) {
      return AppTheme.primaryDark;
    }
    if (isOllamaOnline == true) return const Color(0xFF2E7D32);
    if (isOllamaOnline == false) return const Color(0xFFC62828);
    return AppTheme.darkGraphite;
  }

  String get _statusText {
    if (activeEngine == LocalEngineType.mediaPipeOnDevice) {
      return '⚡ Flutter Edge AI (Gemma 2B)';
    }
    if (isPinging) return 'Testando Ollama...';
    if (isOllamaOnline == true) return 'Ollama Server Online (11434)';
    if (isOllamaOnline == false) return 'Ollama Desconectado (Clique p/ ping)';
    return 'Status Ollama: Não verificado';
  }
}

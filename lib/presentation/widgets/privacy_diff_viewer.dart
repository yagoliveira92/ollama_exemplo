import 'package:flutter/material.dart';
import '../../domain/models/agent_result.dart';
import '../theme/app_theme.dart';

class PrivacyDiffViewer extends StatefulWidget {
  final PrivacyReport privacyReport;

  const PrivacyDiffViewer({super.key, required this.privacyReport});

  @override
  State<PrivacyDiffViewer> createState() => _PrivacyDiffViewerState();
}

class _PrivacyDiffViewerState extends State<PrivacyDiffViewer> {
  int _selectedTabIndex = 1; // Default no Sanitizado

  @override
  Widget build(BuildContext context) {
    final report = widget.privacyReport;

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
              final isCompact = constraints.maxWidth < 450;
              final headerTitle = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    report.hasPii ? Icons.security : Icons.shield_outlined,
                    size: 18,
                    color: report.hasPii ? AppTheme.primaryEmerald : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Firewall Cognitivo On-Device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGraphite,
                    ),
                  ),
                ],
              );

              final badge = report.hasPii
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Text(
                        '${report.detectedPii.length} PII(s) Sanitizado(s)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Text(
                        'Nenhum PII Detectado',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    );

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
                  headerTitle,
                  const Spacer(),
                  badge,
                ],
              );
            },
          ),
          if (report.detectedPii.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: report.detectedPii.map((item) {
                return Chip(
                  avatar: const Icon(Icons.lock_outline, size: 12, color: AppTheme.primaryDark),
                  label: Text('${item.category}: ${item.maskedValue}'),
                  backgroundColor: AppTheme.primaryLight,
                  side: const BorderSide(color: Color(0xFFB2DFDB)),
                  visualDensity: VisualDensity.compact,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                    fontFamily: 'monospace',
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          // Alternador de Visualização
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTabButton(
                index: 0,
                label: 'Texto Bruto (Original)',
                icon: Icons.raw_on,
              ),
              _buildTabButton(
                index: 1,
                label: 'Texto Sanitizado (Higienizado)',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedTabIndex == 1 && report.hasPii
                    ? const Color(0xFF80CBC4)
                    : AppTheme.borderSubtle,
              ),
            ),
            child: Text(
              _selectedTabIndex == 0 ? report.originalText : report.sanitizedText,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.45,
                color: _selectedTabIndex == 0 && report.hasPii
                    ? const Color(0xFFC62828)
                    : AppTheme.darkGraphite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.darkGraphite : AppTheme.backgroundSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.darkGraphite : AppTheme.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.darkGraphite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

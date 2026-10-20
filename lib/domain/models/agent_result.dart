import 'incident_analysis.dart';

enum RouteTarget {
  localOllama,
  cloudLLM,
  semanticCache,
}

class PiiItem {
  final String category;
  final String originalValue;
  final String maskedValue;

  const PiiItem({
    required this.category,
    required this.originalValue,
    required this.maskedValue,
  });
}

class PrivacyReport {
  final bool hasPii;
  final List<PiiItem> detectedPii;
  final String originalText;
  final String sanitizedText;

  const PrivacyReport({
    required this.hasPii,
    required this.detectedPii,
    required this.originalText,
    required this.sanitizedText,
  });

  factory PrivacyReport.clean(String text) {
    return PrivacyReport(
      hasPii: false,
      detectedPii: const [],
      originalText: text,
      sanitizedText: text,
    );
  }
}

class AgentExecutionResult {
  final IncidentAnalysis analysis;
  final String providerName;
  final RouteTarget routeTarget;
  final int latencyMs;
  final double costUsd;
  final bool isCacheHit;
  final PrivacyReport privacyReport;
  final String routeReason;
  final String rawJson;

  const AgentExecutionResult({
    required this.analysis,
    required this.providerName,
    required this.routeTarget,
    required this.latencyMs,
    required this.costUsd,
    required this.isCacheHit,
    required this.privacyReport,
    required this.routeReason,
    required this.rawJson,
  });
}

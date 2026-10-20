import 'dart:convert';

/// Nível de criticidade do incidente
enum IncidentSeverity {
  baixa,
  media,
  alta;

  static IncidentSeverity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'alta':
      case 'high':
      case 'critica':
      case 'crítica':
        return IncidentSeverity.alta;
      case 'media':
      case 'média':
      case 'medium':
        return IncidentSeverity.media;
      case 'baixa':
      case 'low':
      default:
        return IncidentSeverity.baixa;
    }
  }

  String get label {
    switch (this) {
      case IncidentSeverity.alta:
        return 'Alta';
      case IncidentSeverity.media:
        return 'Média';
      case IncidentSeverity.baixa:
        return 'Baixa';
    }
  }
}

/// Dados estruturados estritos extraídos do incidente
class IncidentAnalysis {
  final String incidentType;
  final IncidentSeverity severity;
  final String recommendedAction;
  final List<String> executionTasks;
  final String summary;

  const IncidentAnalysis({
    required this.incidentType,
    required this.severity,
    required this.recommendedAction,
    required this.executionTasks,
    required this.summary,
  });

  factory IncidentAnalysis.fromJson(Map<String, dynamic> json) {
    final tasksRaw = json['execution_tasks'] ?? json['tarefas_a_executar'] ?? json['tasks'];
    final List<String> tasks = [];
    if (tasksRaw is List) {
      for (final item in tasksRaw) {
        if (item != null) tasks.add(item.toString());
      }
    }

    return IncidentAnalysis(
      incidentType: (json['incident_type'] ?? json['tipo_incidente'] ?? 'Falha Não Categorizada').toString(),
      severity: IncidentSeverity.fromString(
        (json['severity'] ?? json['nivel_criticidade'] ?? json['criticidade'])?.toString(),
      ),
      recommendedAction: (json['recommended_action'] ?? json['acao_recomendada'] ?? 'Investigar causa raiz').toString(),
      executionTasks: tasks.isNotEmpty ? tasks : ['Analisar stack trace detalhado', 'Verificar impacto em clientes afetados'],
      summary: (json['summary'] ?? json['resumo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'incident_type': incidentType,
    'severity': severity.label,
    'recommended_action': recommendedAction,
    'execution_tasks': executionTasks,
    if (summary.isNotEmpty) 'summary': summary,
  };

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

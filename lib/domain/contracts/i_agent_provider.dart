import '../models/agent_result.dart';

abstract class IAgentProvider {
  Future<AgentExecutionResult> processIncident(String rawText);
  String get providerName;
}

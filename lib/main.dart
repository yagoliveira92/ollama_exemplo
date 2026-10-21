// ==============================================================================
// EdgeInspector: Sanitizador e Extrator Estruturado de Logs
// Arquitetura de IA Híbrida com Ollama Local (Edge AI On-Device) e Nuvem
//
// DEPENDÊNCIAS NECESSÁRIAS (pubspec.yaml):
//   dependencies:
//     flutter:
//       sdk: flutter
//     http: ^1.2.0 (ou superior)
//
// PADRÕES DE ARQUITETURA ADOTADOS:
// - Clean Architecture & Inversão de Controle (Contrato IAgentProvider)
// - Firewall Cognitivo On-Device (Sanitização estrita de PIIs antes da rede)
// - Roteamento Inteligente (Ollama Local vs Cloud vs Cache Semântico)
// - Cache Semântico em Memória (Similaridade de tokens com resposta < 10ms)
// - Design System Corporativo: Branco (#FFFFFF), Cinza (#F8F9FA), Verde Esmeralda (#00A884)
//   e Grafite (#3D3D3D)
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';
import 'presentation/screens/edge_inspector_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterEdgeAi.initialize(
      inferenceEngines: const [MediaPipeEngine()],
    );
  } catch (e) {
    debugPrint('Aviso: FlutterEdgeAi inicializado em modo fallback: $e');
  }
  runApp(const EdgeInspectorApp());
}

class EdgeInspectorApp extends StatelessWidget {
  const EdgeInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeInspector - IA Híbrida',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const EdgeInspectorScreen(),
    );
  }
}

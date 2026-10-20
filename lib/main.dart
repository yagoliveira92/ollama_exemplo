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
import 'presentation/screens/edge_inspector_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

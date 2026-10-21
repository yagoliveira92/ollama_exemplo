import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_exemplo/data/providers/mediapipe_on_device_provider.dart';
import 'package:ollama_exemplo/data/services/model_manager_service.dart';

void main() {
  group('On-Device Google MediaPipe LLM (Gemma 2B)', () {
    test('ModelManagerService deve reportar nome de modelo padrão e estrutura', () {
      expect(
        ModelManagerService.defaultGemmaModelName,
        equals('gemma3-1b-it-int4.task'),
      );
    });

    test('MediaPipeOnDeviceProvider deve ser instanciado e possuir nome canônico', () {
      final provider = MediaPipeOnDeviceProvider();
      expect(provider.providerName, contains('FlutterEdgeAI (Gemma 2B)'));
      expect(provider.modelName, equals('gemma3-1b-it-int4.task'));
    });
  });
}

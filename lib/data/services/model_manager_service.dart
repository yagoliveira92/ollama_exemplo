import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Serviço responsável pela gestão e localização de modelos LLM armazenados no dispositivo.
class ModelManagerService {
  /// Nome padrão do modelo Gemma 1B quantizado para MediaPipe GenAI (leve para mobile)
  static const String defaultGemmaModelName = 'gemma3-1b-it-int4.task';

  /// Retorna o diretório base preferencial da aplicação onde os modelos são armazenados
  Future<Directory> getModelsDirectory() async {
    final appDocsDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDocsDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Procura e retorna o caminho absoluto onde o modelo estiver presente.
  /// No Android, garante que o modelo esteja dentro do diretório privado da aplicação
  /// para evitar erros de permissão de Scoped Storage (POSIX open() PERMISSION_DENIED no C++).
  Future<String> getModelPath({String filename = defaultGemmaModelName}) async {
    final defaultDir = await getModelsDirectory();
    final internalPath = '${defaultDir.path}/$filename';
    final internalFile = File(internalPath);

    // 1. Se o arquivo específico já está no diretório interno privado, prioridade total
    if (await internalFile.exists()) {
      return internalPath;
    }

    // 2. Se houver qualquer outro modelo instalado (.task ou .bin) no diretório privado, use-o (ex: modelo 0.5B ou 1B mais leve)
    final anyInstalled = await findAnyInstalledModel();
    if (anyInstalled != null && filename == defaultGemmaModelName) {
      return anyInstalled;
    }

    // 3. Procura nos locais candidatos
    final candidatePaths = await getCandidatePaths(filename: filename);
    for (final candidate in candidatePaths) {
      if (candidate == internalPath) continue;
      final file = File(candidate);
      if (await file.exists()) {
        try {
          // Copia/migra para o diretório interno para garantir permissão irrestrita ao C++ do MediaPipe
          await file.copy(internalPath);
          return internalPath;
        } catch (_) {
          return candidate;
        }
      }
    }

    // Fallback padrão
    return internalPath;
  }

  /// Retorna o caminho de qualquer modelo leve (.task ou .bin) presente no diretório
  /// Ordena pelo menor tamanho para favorecer modelos que cabem na RAM de aparelhos de entrada.
  Future<String?> findAnyInstalledModel() async {
    final dir = await getModelsDirectory();
    if (await dir.exists()) {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.bin') || f.path.endsWith('.task'))
          .toList();
      if (files.isNotEmpty) {
        files.sort((a, b) => a.lengthSync().compareTo(b.lengthSync()));
        return files.first.path;
      }
    }
    return null;
  }

  /// Retorna lista de possíveis locais de busca para o arquivo do modelo
  Future<List<String>> getCandidatePaths({String filename = defaultGemmaModelName}) async {
    final list = <String>[];

    // 1. Diretório padrão de documentos do aplicativo
    final appDocsDir = await getApplicationDocumentsDirectory();
    list.add('${appDocsDir.path}/models/$filename');
    list.add('${appDocsDir.path}/$filename');

    // 2. Diretório externo do aplicativo no Android
    if (Platform.isAndroid) {
      try {
        final extDirs = await getExternalStorageDirectories();
        if (extDirs != null) {
          for (final dir in extDirs) {
            list.add('${dir.path}/models/$filename');
            list.add('${dir.path}/$filename');
          }
        }
      } catch (_) {}

      // Pastas padrão de Downloads no Android
      list.add('/sdcard/Download/$filename');
      list.add('/storage/emulated/0/Download/$filename');
      list.add('/sdcard/Android/data/com.example.ollama_exemplo/files/models/$filename');
    }

    // 3. Pasta Downloads do usuário no Desktop (macOS/Linux)
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        list.add('$home/Downloads/$filename');
        list.add('$home/models/$filename');
      }
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          list.add('${downloadsDir.path}/$filename');
        }
      } catch (_) {}
    }

    return list;
  }

  /// Verifica se o modelo já está baixado/presente no dispositivo
  Future<bool> isModelInstalled({String filename = defaultGemmaModelName}) async {
    final path = await getModelPath(filename: filename);
    final file = File(path);
    return await file.exists();
  }

  /// Retorna o tamanho do modelo em Megabytes (MB)
  Future<double?> getModelSizeMb({String filename = defaultGemmaModelName}) async {
    final path = await getModelPath(filename: filename);
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    }
    return null;
  }
}

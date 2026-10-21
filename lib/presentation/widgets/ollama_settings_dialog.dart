import 'package:flutter/material.dart';
import '../../data/providers/hybrid_router.dart';
import '../../data/providers/ollama_local_provider.dart';
import '../../data/services/model_manager_service.dart';
import '../theme/app_theme.dart';

class OllamaSettingsDialog extends StatefulWidget {
  final HybridRouter router;
  final VoidCallback onSaved;

  const OllamaSettingsDialog({
    super.key,
    required this.router,
    required this.onSaved,
  });

  @override
  State<OllamaSettingsDialog> createState() => _OllamaSettingsDialogState();
}

class _OllamaSettingsDialogState extends State<OllamaSettingsDialog> {
  late LocalEngineType _selectedEngine;
  late final TextEditingController _urlController;
  late final TextEditingController _modelController;

  final ModelManagerService _modelManager = ModelManagerService();
  bool _isCheckingOnDevice = true;
  bool _isOnDeviceInstalled = false;
  double? _onDeviceSizeMb;
  String _onDevicePath = '';

  bool _isTestingOllama = false;
  bool? _ollamaTestResult;
  List<String> _installedOllamaModels = [];

  bool _isTestingMediaPipe = false;
  bool? _mediaPipeTestResult;
  String? _mediaPipeError;

  @override
  void initState() {
    super.initState();
    _selectedEngine = widget.router.activeLocalEngine;
    _urlController = TextEditingController(text: widget.router.localProvider.baseUrl);
    _modelController = TextEditingController(text: widget.router.localProvider.model);

    _checkOnDeviceModel();
    _loadOllamaModels();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _checkOnDeviceModel() async {
    setState(() => _isCheckingOnDevice = true);
    final installed = await _modelManager.isModelInstalled();
    final sizeMb = await _modelManager.getModelSizeMb();
    final path = await _modelManager.getModelPath();

    if (mounted) {
      setState(() {
        _isOnDeviceInstalled = installed;
        _onDeviceSizeMb = sizeMb;
        _onDevicePath = path;
        _isCheckingOnDevice = false;
      });
    }
  }

  Future<void> _loadOllamaModels() async {
    final models = await widget.router.localProvider.listInstalledModels();
    if (mounted && models.isNotEmpty) {
      setState(() {
        _installedOllamaModels = models;
      });
    }
  }

  Future<void> _testMediaPipe() async {
    setState(() {
      _isTestingMediaPipe = true;
      _mediaPipeTestResult = null;
      _mediaPipeError = null;
    });

    try {
      final ok = await widget.router.mediaPipeProvider.ensureInitialized();
      if (mounted) {
        setState(() {
          _isTestingMediaPipe = false;
          _mediaPipeTestResult = ok;
          if (!ok) {
            _mediaPipeError = widget.router.mediaPipeProvider.llmService.lastError;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingMediaPipe = false;
          _mediaPipeTestResult = false;
          _mediaPipeError = e.toString();
        });
      }
    }
  }

  Future<void> _testOllama() async {
    setState(() {
      _isTestingOllama = true;
      _ollamaTestResult = null;
    });

    final tempProvider = OllamaLocalProvider(
      baseUrl: _urlController.text.trim(),
      model: _modelController.text.trim(),
    );

    final ok = await tempProvider.ping();
    final models = await tempProvider.listInstalledModels();

    if (mounted) {
      setState(() {
        _isTestingOllama = false;
        _ollamaTestResult = ok;
        if (models.isNotEmpty) {
          _installedOllamaModels = models;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.memory, size: 20, color: AppTheme.primaryDark),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Configurações de Engine Edge AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGraphite,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha a engine para inferência local e privada:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            // Opção 1: Google MediaPipe On-Device (Gemma 2B)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedEngine = LocalEngineType.mediaPipeOnDevice),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedEngine == LocalEngineType.mediaPipeOnDevice
                      ? const Color(0xFFE8F8F5)
                      : AppTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedEngine == LocalEngineType.mediaPipeOnDevice
                        ? AppTheme.primaryEmerald
                        : AppTheme.borderSubtle,
                    width: _selectedEngine == LocalEngineType.mediaPipeOnDevice ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedEngine == LocalEngineType.mediaPipeOnDevice
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedEngine == LocalEngineType.mediaPipeOnDevice
                          ? AppTheme.primaryEmerald
                          : AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ Flutter Edge AI (On-Device)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGraphite,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gemma 2B nativo via NPU/GPU no próprio dispositivo. Zero rede, privacidade absoluta.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Opção 2: Ollama Local (Rede / Host)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedEngine = LocalEngineType.ollamaServer),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedEngine == LocalEngineType.ollamaServer
                      ? const Color(0xFFE8F8F5)
                      : AppTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedEngine == LocalEngineType.ollamaServer
                        ? AppTheme.primaryEmerald
                        : AppTheme.borderSubtle,
                    width: _selectedEngine == LocalEngineType.ollamaServer ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedEngine == LocalEngineType.ollamaServer
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedEngine == LocalEngineType.ollamaServer
                          ? AppTheme.primaryEmerald
                          : AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🖥️ Servidor Ollama Local (Rede / Host)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGraphite,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Conecta via HTTP ao Ollama rodando no Mac/PC local na rede Wi-Fi.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderSubtle),
            const SizedBox(height: 8),

            // Detalhes da Engine Selecionada
            if (_selectedEngine == LocalEngineType.mediaPipeOnDevice) ...[
              const Text(
                'Status do Modelo Gemma 2B On-Device:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGraphite,
                ),
              ),
              const SizedBox(height: 8),
              if (_isCheckingOnDevice)
                const LinearProgressIndicator(color: AppTheme.primaryEmerald)
              else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isOnDeviceInstalled
                        ? const Color(0xFFE8F8F5)
                        : const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isOnDeviceInstalled
                          ? AppTheme.primaryEmerald
                          : const Color(0xFFFFA726),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOnDeviceInstalled ? Icons.check_circle : Icons.warning_amber,
                        size: 20,
                        color: _isOnDeviceInstalled
                            ? AppTheme.primaryEmerald
                            : const Color(0xFFF57C00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnDeviceInstalled
                                  ? 'Arquivo do Modelo Encontrado (${_onDeviceSizeMb?.toStringAsFixed(1)} MB)'
                                  : 'Arquivo do modelo não encontrado',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isOnDeviceInstalled
                                    ? AppTheme.primaryDark
                                    : const Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _onDevicePath,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!_isOnDeviceInstalled) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Text(
                      'Para instalar no aparelho Android:\n'
                      'adb push gemma-2b-it-gpu-int4.bin /sdcard/Android/data/com.example.ollama_exemplo/files/models/\n'
                      '(Ou coloque o arquivo na pasta de documentos da aplicação).',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppTheme.darkGraphite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: _isTestingMediaPipe ? null : _testMediaPipe,
                  icon: _isTestingMediaPipe
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _mediaPipeTestResult == true
                              ? Icons.check
                              : _mediaPipeTestResult == false
                                  ? Icons.error_outline
                                  : Icons.play_arrow,
                          size: 16,
                          color: _mediaPipeTestResult == true
                              ? AppTheme.primaryEmerald
                              : _mediaPipeTestResult == false
                                  ? Colors.red
                                  : AppTheme.darkGraphite,
                        ),
                  label: Text(
                    _isTestingMediaPipe
                        ? 'Carregando na GPU...'
                        : _mediaPipeTestResult == true
                            ? 'Inicializado com Sucesso na GPU/NPU'
                            : _mediaPipeTestResult == false
                                ? 'Falha ao Carregar'
                                : 'Testar Inicialização na GPU/NPU',
                    style: TextStyle(
                      fontSize: 12,
                      color: _mediaPipeTestResult == true
                          ? AppTheme.primaryEmerald
                          : _mediaPipeTestResult == false
                              ? Colors.red
                              : AppTheme.darkGraphite,
                    ),
                  ),
                ),
                if (_mediaPipeError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _mediaPipeError!,
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                ],
              ],
            ] else ...[
              // Configurações do Ollama
              const Text(
                'Endereço URL do Ollama:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGraphite,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'Ex: http://192.168.3.172:11434',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tag do Modelo:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGraphite,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  hintText: 'Ex: gemma4:e4b-mlx',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              if (_installedOllamaModels.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _installedOllamaModels.map((m) {
                    final isSelected = _modelController.text == m;
                    return InkWell(
                      onTap: () => setState(() => _modelController.text = m),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryLight
                              : AppTheme.backgroundSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryEmerald
                                : AppTheme.borderSubtle,
                          ),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: isSelected
                                ? AppTheme.primaryDark
                                : AppTheme.darkGraphite,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isTestingOllama ? null : _testOllama,
                icon: _isTestingOllama
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _ollamaTestResult == true
                            ? Icons.check
                            : _ollamaTestResult == false
                                ? Icons.close
                                : Icons.sync,
                        size: 16,
                        color: _ollamaTestResult == true
                            ? AppTheme.primaryEmerald
                            : _ollamaTestResult == false
                                ? Colors.red
                                : AppTheme.darkGraphite,
                      ),
                label: Text(
                  _isTestingOllama
                      ? 'Testando...'
                      : _ollamaTestResult == true
                          ? 'Ollama Conectado'
                          : _ollamaTestResult == false
                              ? 'Falha ao Conectar'
                              : 'Testar Conexão Ollama',
                  style: TextStyle(
                    fontSize: 12,
                    color: _ollamaTestResult == true
                        ? AppTheme.primaryEmerald
                        : _ollamaTestResult == false
                            ? Colors.red
                            : AppTheme.darkGraphite,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.router.activeLocalEngine = _selectedEngine;
            widget.router.localProvider.baseUrl = _urlController.text.trim();
            widget.router.localProvider.model = _modelController.text.trim();
            widget.onSaved();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

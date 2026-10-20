import 'package:flutter/material.dart';
import '../../data/providers/ollama_local_provider.dart';
import '../theme/app_theme.dart';

class OllamaSettingsDialog extends StatefulWidget {
  final OllamaLocalProvider localProvider;
  final VoidCallback onSaved;

  const OllamaSettingsDialog({
    super.key,
    required this.localProvider,
    required this.onSaved,
  });

  @override
  State<OllamaSettingsDialog> createState() => _OllamaSettingsDialogState();
}

class _OllamaSettingsDialogState extends State<OllamaSettingsDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _modelController;
  bool _isTesting = false;
  bool? _testResult;
  List<String> _installedModels = [];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.localProvider.baseUrl);
    _modelController = TextEditingController(text: widget.localProvider.model);
    _loadModels();
  }

  Future<void> _loadModels() async {
    final models = await widget.localProvider.listInstalledModels();
    if (mounted && models.isNotEmpty) {
      setState(() {
        _installedModels = models;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final tempProvider = OllamaLocalProvider(
      baseUrl: _urlController.text.trim(),
      model: _modelController.text.trim(),
    );

    final ok = await tempProvider.ping();
    final models = await tempProvider.listInstalledModels();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = ok;
        if (models.isNotEmpty) {
          _installedModels = models;
        }
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      title: const Row(
        children: [
          Icon(Icons.settings_input_component, size: 20, color: AppTheme.primaryEmerald),
          SizedBox(width: 8),
          Text(
            'Configurações do Ollama Local',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkGraphite,
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
              'Endpoint HTTP do Daemon:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkGraphite),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'http://localhost:11434',
                prefixIcon: Icon(Icons.link, size: 16),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nome do Modelo On-Device:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkGraphite),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _modelController,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'gemma4:e4b-mlx',
                prefixIcon: Icon(Icons.memory, size: 16),
              ),
            ),
            if (_installedModels.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Modelos detectados no Ollama:',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _installedModels.map((m) {
                  return ActionChip(
                    label: Text(m, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    backgroundColor: AppTheme.backgroundSurface,
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    onPressed: () {
                      _modelController.text = m;
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            // Botão de Ping
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _testResult == true
                          ? Icons.check_circle
                          : _testResult == false
                              ? Icons.error
                              : Icons.network_ping,
                      size: 16,
                      color: _testResult == true
                          ? AppTheme.primaryEmerald
                          : _testResult == false
                              ? const Color(0xFFC62828)
                              : AppTheme.darkGraphite,
                    ),
              label: Text(
                _isTesting
                    ? 'Testando conexão...'
                    : _testResult == true
                        ? 'Conexão OK com Ollama!'
                        : _testResult == false
                            ? 'Falha de Conexão'
                            : 'Testar Ping no Daemon',
                style: TextStyle(
                  fontSize: 12,
                  color: _testResult == true
                      ? AppTheme.primaryEmerald
                      : _testResult == false
                          ? const Color(0xFFC62828)
                          : AppTheme.darkGraphite,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _testResult == true
                      ? AppTheme.primaryEmerald
                      : _testResult == false
                          ? const Color(0xFFEF9A9A)
                          : AppTheme.borderSubtle,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dica: Se estiver usando o Android Emulator, utilize http://10.0.2.2:11434. '
                      'No terminal do seu computador, execute "ollama serve" para manter o daemon ativo.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
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
            widget.localProvider.baseUrl = _urlController.text.trim();
            widget.localProvider.model = _modelController.text.trim();
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

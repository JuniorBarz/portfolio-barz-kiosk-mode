import 'package:flutter/material.dart';

import '../../core/platform/kiosk_method_channel.dart';
import '../../models/kiosk_status.dart';
import '../../services/config_service.dart';
import '../../services/kiosk_service.dart';
import 'app_picker_screen.dart';
import 'pin_change_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selected = 'Nenhum aplicativo selecionado';
  KioskStatus? _status;
  final _kioskService = KioskService(KioskMethodChannel());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = await ConfigService().loadSelectedApp();
    KioskStatus? status;
    try {
      status = await _kioskService.getStatus();
    } on Object {
      status = null;
    }
    if (!mounted) return;
    setState(() {
      _selected = app?.label ?? 'Nenhum aplicativo selecionado';
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Aplicativo bloqueado'),
            subtitle: Text(_selected),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppPickerScreen(),
                ),
              );
              await _load();
            },
          ),
          const Divider(),
          _PermissionTile(
            title: 'Acesso de uso',
            enabled: _status?.hasUsageStatsPermission == true,
            onTap: () async {
              await _kioskService.openUsageAccessSettings();
              await _load();
            },
          ),
          _PermissionTile(
            title: 'Sobrepor a outros apps',
            enabled: _status?.hasOverlayPermission == true,
            onTap: () async {
              await _kioskService.openOverlaySettings();
              await _load();
            },
          ),
          _PermissionTile(
            title: 'Launcher padrao',
            enabled: _status?.isDefaultLauncher == true,
            onTap: () async {
              await _kioskService.openHomeSettings();
              await _load();
            },
          ),
          _PermissionTile(
            title: 'Acessibilidade opcional',
            enabled: _status?.isAccessibilityEnabled == true,
            onTap: () async {
              await _kioskService.openAccessibilitySettings();
              await _load();
            },
          ),
          SwitchListTile(
            title: const Text('Mostrar area dos 7 toques'),
            subtitle: const Text('Use para validar o ponto secreto no app.'),
            value: _status?.isOverlayDebugEnabled ?? true,
            onChanged: (value) async {
              await _kioskService.setSecretTapOverlayDebug(value);
              await _load();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Area dos 7 toques visivel.'
                        : 'Area dos 7 toques invisivel.',
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('PIN'),
            subtitle: const Text('Troca de PIN protegida pelo fluxo seguro.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PinChangeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(enabled ? 'Ativado' : 'Pendente'),
      leading: Icon(
        enabled ? Icons.check_circle : Icons.error_outline,
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}


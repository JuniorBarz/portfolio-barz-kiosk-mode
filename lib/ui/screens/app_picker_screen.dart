import 'package:flutter/material.dart';

import '../../core/platform/kiosk_method_channel.dart';
import '../../models/installed_app.dart';
import '../../services/app_catalog_service.dart';
import '../../services/config_service.dart';

class AppPickerScreen extends StatelessWidget {
  const AppPickerScreen({super.key});

  Future<List<InstalledApp>> _loadApps() {
    return AppCatalogService(
      platform: MethodChannelAppCatalogPlatform(KioskMethodChannel()),
    ).listInstalledApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar aplicativo')),
      body: FutureBuilder<List<InstalledApp>>(
        future: _loadApps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao listar apps: ${snapshot.error}'),
            );
          }
          final apps = snapshot.data ?? const [];
          if (apps.isEmpty) {
            return const Center(child: Text('Nenhum aplicativo encontrado.'));
          }
          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return ListTile(
                title: Text(app.label),
                subtitle: Text(app.packageName),
                onTap: () async {
                  await ConfigService().saveSelectedApp(app);
                  if (context.mounted) Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}


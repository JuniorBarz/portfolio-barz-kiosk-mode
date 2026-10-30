import 'package:flutter/material.dart';

import '../../core/constants/kiosk_constants.dart';
import '../../core/platform/kiosk_method_channel.dart';
import '../../models/kiosk_state.dart';
import '../../services/app_catalog_service.dart';
import '../../services/config_service.dart';
import '../../services/kiosk_controller.dart';
import '../../services/kiosk_service.dart';
import '../../services/secret_tap_detector.dart';
import '../widgets/status_banner.dart';
import 'pin_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _secretTapDetector = SecretTapDetector(
    requiredTaps: KioskConstants.secretTapCount,
    window: const Duration(seconds: 3),
  );
  var _busy = false;
  var _pinOpening = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPinIfRequested();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openPinIfRequested();
    }
  }

  Future<void> _openPinIfRequested() async {
    if (_pinOpening || !mounted) return;
    final kioskService = KioskService(KioskMethodChannel());
    bool shouldOpen;
    try {
      shouldOpen = await kioskService.consumeUnlockRequest();
    } on Object {
      shouldOpen = false;
    }
    if (!mounted || !shouldOpen) return;
    await _openPin(returnToKioskOnInvalid: true, beginUnlock: false);
  }

  Future<void> _registerSecretTap() async {
    final triggered = _secretTapDetector.registerTap(
      DateTime.now(),
      enabled: !_busy && !_pinOpening,
    );
    if (triggered) {
      await _openPin();
    }
  }

  Future<void> _openPin({
    bool returnToKioskOnInvalid = false,
    bool beginUnlock = true,
  }) async {
    if (_pinOpening) return;
    setState(() => _pinOpening = true);
    final kioskService = KioskService(KioskMethodChannel());
    if (beginUnlock) {
      await kioskService.beginUnlock();
    }
    if (!mounted) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PinScreen(returnToKioskOnInvalid: returnToKioskOnInvalid),
          ),
        )
        .whenComplete(() async {
          await kioskService.endUnlock();
          _secretTapDetector.reset();
          if (mounted) {
            setState(() => _pinOpening = false);
          } else {
            _pinOpening = false;
          }
        });
  }

  Future<void> _startKiosk() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final config = ConfigService();
    final selectedApp = await config.loadSelectedApp();
    if (!mounted) return;
    if (selectedApp == null) {
      setState(() {
        _busy = false;
        _message = 'Selecione um aplicativo antes de iniciar.';
      });
      return;
    }

    final channel = KioskMethodChannel();
    final kioskService = KioskService(channel);
    final status = await kioskService.getStatus();
    if (!status.hasUsageStatsPermission) {
      await kioskService.openUsageAccessSettings();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Ative o acesso de uso para continuar.';
      });
      return;
    }
    if (!status.hasOverlayPermission) {
      await kioskService.openOverlaySettings();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Ative a permissao de sobreposicao para continuar.';
      });
      return;
    }
    if (!status.isDefaultLauncher) {
      await kioskService.openHomeSettings();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Defina Barz Kiosk Mode como launcher padrao.';
      });
      return;
    }

    final controller = KioskController(
      initialState: KioskState.initial().copyWith(
        selectedApp: selectedApp,
        isPinConfigured: true,
        requiresPinChange: false,
      ),
      kioskService: kioskService,
      appCatalogService: AppCatalogService(
        platform: MethodChannelAppCatalogPlatform(channel),
      ),
      now: DateTime.now,
    );

    await controller.start();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message =
          controller.state.lastError?.message ??
          'Modo atual: ${controller.state.mode.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _registerSecretTap,
      child: Scaffold(
        appBar: AppBar(title: const Text('Barz Kiosk Mode')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusBanner(
                message: KioskConstants.fallbackWarning,
                isWarning: true,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _startKiosk,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock),
                label: const Text('Iniciar modo quiosque'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.settings),
                label: const Text('Configuracoes'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


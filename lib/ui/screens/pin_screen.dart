import 'package:flutter/material.dart';

import '../../core/platform/kiosk_method_channel.dart';
import '../../services/config_service.dart';
import '../../services/kiosk_service.dart';
import '../../services/pin_service.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, this.returnToKioskOnInvalid = false});

  final bool returnToKioskOnInvalid;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String? _error;
  var _busy = false;

  void _append(String digit) {
    if (_busy || _pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final config = ConfigService();
    final record = await config.loadPinRecord();
    if (!mounted) return;
    if (record == null) {
      setState(() {
        _busy = false;
        _error = 'Defina um PIN nas configuracoes.';
      });
      await _returnToKioskIfNeeded();
      return;
    }

    final result = PinService().verify(pin: _pin, record: record);
    if (!result.isValid) {
      await config.savePinRecord(result.record);
      if (result.delay > Duration.zero) {
        await Future<void>.delayed(result.delay);
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _pin = '';
        _error = result.isLocked
            ? 'PIN bloqueado por tentativas invalidas.'
            : 'PIN invalido.';
      });
      await _returnToKioskIfNeeded();
      return;
    }

    await config.savePinRecord(result.record);
    await KioskService(KioskMethodChannel()).stopKiosk();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _returnToKioskIfNeeded() async {
    if (!widget.returnToKioskOnInvalid) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await KioskService(KioskMethodChannel()).endUnlock();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Desbloqueio')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Digite o PIN',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              '*' * _pin.length,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: [
                for (final digit in [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                ])
                  FilledButton(
                    onPressed: () => _append(digit),
                    child: Text(digit),
                  ),
                OutlinedButton(
                  onPressed: _backspace,
                  child: const Text('Apagar'),
                ),
                FilledButton(
                  onPressed: () => _append('0'),
                  child: const Text('0'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


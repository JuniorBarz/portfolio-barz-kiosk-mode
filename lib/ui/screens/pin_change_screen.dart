import 'package:flutter/material.dart';

import '../../services/config_service.dart';
import '../../services/pin_change_service.dart';
import '../../services/pin_service.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  var _busy = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
      _isError = false;
    });

    final service = PinChangeService(
      configStore: ConfigService(),
      pinService: PinService(),
    );
    final result = await service.changePin(
      currentPin: _currentController.text,
      newPin: _newController.text,
      confirmPin: _confirmController.text,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _isError = result != PinChangeResult.changed;
      _message = switch (result) {
        PinChangeResult.changed => 'PIN alterado com sucesso.',
        PinChangeResult.invalidCurrentPin => 'PIN atual invalido.',
        PinChangeResult.invalidNewPin => 'O novo PIN deve ter 6 digitos.',
        PinChangeResult.mismatch => 'A confirmacao nao confere.',
        PinChangeResult.locked => 'PIN bloqueado por tentativas invalidas.',
      };
    });

    if (result == PinChangeResult.changed) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar PIN')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _currentController,
            decoration: const InputDecoration(labelText: 'PIN atual'),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            decoration: const InputDecoration(labelText: 'Novo PIN'),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(labelText: 'Confirmar novo PIN'),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Salvar PIN'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: TextStyle(
                color: _isError ? colorScheme.error : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


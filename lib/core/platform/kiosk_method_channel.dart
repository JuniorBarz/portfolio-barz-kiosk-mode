import 'package:flutter/services.dart';

class NativeCallResult<T> {
  const NativeCallResult({required this.success, this.error, this.data});

  final bool success;
  final String? error;
  final T? data;
}

class KioskMethodChannel {
  KioskMethodChannel({MethodChannel? methodChannel})
    : _channel = methodChannel ?? const MethodChannel('kiosk_manager');

  final MethodChannel _channel;

  Future<NativeCallResult<T>> invoke<T>(
    String method, {
    Map<String, Object?> arguments = const {},
    T Function(Object? data)? parse,
  }) async {
    final raw = await _channel.invokeMethod<Object?>(method, arguments);
    if (raw is! Map<Object?, Object?>) {
      return NativeCallResult<T>(
        success: false,
        error: 'Malformed native response for $method.',
      );
    }

    final success = raw['success'];
    if (success is! bool) {
      return NativeCallResult<T>(
        success: false,
        error: 'Malformed native response for $method.',
      );
    }

    final error = raw['error'] as String?;
    final data = raw.containsKey('data') && parse != null
        ? parse(raw['data'])
        : raw['data'] as T?;

    return NativeCallResult<T>(success: success, error: error, data: data);
  }
}


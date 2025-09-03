import 'dart:developer' as developer;

/// Basic analytics and crash reporting helper.
///
/// This class can be wired to services like Firebase Analytics or Sentry
/// to collect metrics and error reports ensuring parity with the original
/// Flutter implementation.
class MonitoringService {
  void logEvent(String name, [Map<String, Object?>? parameters]) {
    developer.log('event: ' + name, name: 'analytics', error: parameters);
  }

  void reportError(Object error, StackTrace stackTrace) {
    developer.log('error: ' + error.toString(), name: 'crash', error: stackTrace);
  }
}

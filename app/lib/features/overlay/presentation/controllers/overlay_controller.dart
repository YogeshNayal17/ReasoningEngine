import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/overlay_bridge.dart';

class OverlayState {
  const OverlayState({required this.hasPermission, required this.isRunning});

  const OverlayState.initial() : hasPermission = false, isRunning = false;

  final bool hasPermission;
  final bool isRunning;

  OverlayState copyWith({bool? hasPermission, bool? isRunning}) {
    return OverlayState(
      hasPermission: hasPermission ?? this.hasPermission,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

/// Reflects and drives the native overlay bubble's permission/running
/// state. A plain [Notifier] (rather than [AsyncNotifier]) fits better
/// here than a one-shot async load: [refresh] is called repeatedly —
/// once on startup and again whenever the app resumes (e.g. after the
/// user grants the overlay permission in system Settings and switches
/// back) — rather than loaded once and left alone.
class OverlayController extends Notifier<OverlayState> {
  late final OverlayBridge _bridge;
  late final AppLogger _logger;

  @override
  OverlayState build() {
    _bridge = ref.watch(overlayBridgeProvider);
    _logger = ref.watch(appLoggerProvider);
    unawaited(_refresh());
    return const OverlayState.initial();
  }

  Future<void> refresh() => _refresh();

  Future<void> requestPermission() async {
    try {
      await _bridge.requestPermission();
    } catch (error, stackTrace) {
      _logger.error('Failed to request overlay permission', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> startOverlay() async {
    try {
      final started = await _bridge.start();
      state = state.copyWith(isRunning: started);
    } catch (error, stackTrace) {
      _logger.error('Failed to start overlay', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> stopOverlay() async {
    try {
      await _bridge.stop();
      state = state.copyWith(isRunning: false);
    } catch (error, stackTrace) {
      _logger.error('Failed to stop overlay', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _refresh() async {
    try {
      final hasPermission = await _bridge.hasPermission();
      final isRunning = await _bridge.isRunning();
      state = state.copyWith(hasPermission: hasPermission, isRunning: isRunning);
    } catch (error, stackTrace) {
      _logger.error('Failed to refresh overlay state', error: error, stackTrace: stackTrace);
    }
  }
}

final overlayControllerProvider = NotifierProvider<OverlayController, OverlayState>(
  OverlayController.new,
);

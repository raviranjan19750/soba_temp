import 'dart:async';

import 'package:flutter/material.dart';

enum AutoSaveState { idle, saving, saved, error }

/// Debounced auto-save helper for text-heavy planning screens.
class DebouncedAutoSave {
  DebouncedAutoSave({
    this.delay = const Duration(milliseconds: 1200),
  });

  final Duration delay;
  Timer? _timer;
  AutoSaveState _state = AutoSaveState.idle;
  String? _errorMessage;

  AutoSaveState get state => _state;
  String? get errorMessage => _errorMessage;

  void schedule(Future<void> Function() save, VoidCallback onStateChanged) {
    _timer?.cancel();
    _state = AutoSaveState.idle;
    onStateChanged();
    _timer = Timer(delay, () async {
      _state = AutoSaveState.saving;
      onStateChanged();
      try {
        await save();
        _state = AutoSaveState.saved;
        _errorMessage = null;
      } catch (e) {
        _state = AutoSaveState.error;
        _errorMessage = e.toString();
      }
      onStateChanged();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

class AutoSaveStatusChip extends StatelessWidget {
  const AutoSaveStatusChip({
    super.key,
    required this.state,
    this.errorMessage,
  });

  final AutoSaveState state;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (state == AutoSaveState.idle) return const SizedBox.shrink();

    late final Color bg;
    late final Color fg;
    late final String label;

    switch (state) {
      case AutoSaveState.saving:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF1E40AF);
        label = 'Saving…';
      case AutoSaveState.saved:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Saved';
      case AutoSaveState.error:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'Save failed';
      case AutoSaveState.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == AutoSaveState.saving)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
            ),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
          if (state == AutoSaveState.error && errorMessage != null) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: errorMessage!,
              child: Icon(Icons.info_outline, size: 14, color: fg),
            ),
          ],
        ],
      ),
    );
  }
}

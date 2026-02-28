import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../controllers/tts_controller.dart';

/// Small speaker/listen button with optional label. Shows state: idle (speaker),
/// loading (spinner), playing (pause icon), paused (play icon). Disabled when [text] is empty.
class TtsListenButton extends StatelessWidget {
  final TtsController controller;
  final String text;
  final bool showLabel;

  const TtsListenButton({
    super.key,
    required this.controller,
    required this.text,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = text.trim().isNotEmpty;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final isLoading = state == TtsState.loading;
        final isPlaying = state == TtsState.playing;
        final isPaused = state == TtsState.paused;

        Widget icon;
        if (isLoading) {
          icon = SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.secondaryColor,
            ),
          );
        } else if (isPlaying) {
          icon = const Icon(Icons.pause_rounded, size: 22, color: AppTheme.secondaryColor);
        } else if (isPaused) {
          icon = const Icon(Icons.play_arrow_rounded, size: 22, color: AppTheme.secondaryColor);
        } else {
          icon = Icon(
            Icons.volume_up_rounded,
            size: 22,
            color: enabled ? AppTheme.secondaryColor : Colors.grey,
          );
        }

        final button = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && !isLoading
                ? () => controller.toggleListen(text)
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Text(
                      isLoading
                          ? 'Loading...'
                          : isPlaying
                              ? 'Pause'
                              : isPaused
                                  ? 'Resume'
                                  : 'Listen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled ? AppTheme.secondaryColor : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        return button;
      },
    );
  }
}

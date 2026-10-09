import 'package:flutter/material.dart';

class VoiceInputButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final String language;

  const VoiceInputButton({
    super.key,
    this.isRecording = false,
    this.onStartRecording,
    this.onStopRecording,
    this.language = 'uz',
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _animController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = widget.isRecording;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isRecording ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () {
              if (isRecording) {
                widget.onStopRecording?.call();
              } else {
                widget.onStartRecording?.call();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red.shade600 : theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : theme.colorScheme.primary)
                        .withAlpha(isRecording ? 120 : 60),
                    blurRadius: isRecording ? 16 : 8,
                    spreadRadius: isRecording ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}

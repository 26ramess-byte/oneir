import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

/// Shared layout for the three "illustration + heading + Continue" screens
/// (Meet Vanya, Protect Together, Why Oneir). Uses a real flexible Column
/// so text and the button can never overlap regardless of text length.
class _IllustrationHeadingScreen extends StatelessWidget {
  final String placeholderDescription;
  final Widget heading;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final double progress;
  final String buttonLabel;

  const _IllustrationHeadingScreen({
    required this.placeholderDescription,
    required this.heading,
    required this.onNext,
    required this.progress,
    this.onBack,
    this.buttonLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: progress, onBack: onBack),
              const SizedBox(height: 8),
              Expanded(
                flex: 5,
                child: Center(child: OneirAssetPlaceholder(description: placeholderDescription, width: 220, height: 260)),
              ),
              const SizedBox(height: 16),
              heading,
              const Spacer(),
              OneirPrimaryButton(label: buttonLabel, onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }
}

class MeetVanyaScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const MeetVanyaScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return _IllustrationHeadingScreen(
      placeholderDescription: 'Vanya animation: waving hello',
      progress: 1 / 14,
      onBack: onBack,
      heading: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 34, letterSpacing: -0.6, height: 1.15, color: OneirColors.text),
          children: [
            TextSpan(text: "Hi, I'm ", style: const TextStyle(fontWeight: FontWeight.w500)),
            TextSpan(text: 'Vanya', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onNext: onNext,
      buttonLabel: 'Nice to meet you',
    );
  }
}

class ProtectTogetherScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const ProtectTogetherScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return _IllustrationHeadingScreen(
      placeholderDescription: 'Vanya animation: speaking',
      progress: 2 / 14,
      onBack: onBack,
      heading: Text("I'll help you stay focused.",
          textAlign: TextAlign.center,
          style: OneirText.heading.copyWith(fontSize: 30, height: 1.2)),
      onNext: onNext,
      buttonLabel: 'I like the sound of that',
    );
  }
}

class WhyOneirScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WhyOneirScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return _IllustrationHeadingScreen(
      placeholderDescription: 'Vanya illustration: thinking',
      progress: 1.0,
      onBack: onBack,
      heading: Text('Most apps are designed to steal your attention.',
          textAlign: TextAlign.center,
          style: OneirText.heading.copyWith(fontSize: 30, height: 1.2)),
      onNext: onNext,
    );
  }
}

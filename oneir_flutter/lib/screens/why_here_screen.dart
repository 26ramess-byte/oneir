import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';

class _ReasonOption {
  final String label;
  final IconData icon;
  const _ReasonOption(this.label, this.icon);
}

const _reasons = [
  _ReasonOption('Reduce scrolling', Icons.hourglass_bottom),
  _ReasonOption('Study focus', Icons.menu_book_outlined),
  _ReasonOption('Sleep better', Icons.nightlight_outlined),
  _ReasonOption('Something else', Icons.help_outline),
];

/// Step 4 of the 12-step flow -- "Why Are You Here?" A single-select reason
/// picker, styled to match the reference onboarding (progress header +
/// icon/label selection rows + pill button with circular accent).
class WhyHereScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WhyHereScreen({super.key, required this.onNext, this.onBack});

  @override
  State<WhyHereScreen> createState() => _WhyHereScreenState();
}

class _WhyHereScreenState extends State<WhyHereScreen> {
  String? _selected;

  Future<void> _handleContinue() async {
    if (_selected == null) return;
    await OneirProtection.saveUserReason(_selected!);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 4 / 14, onBack: widget.onBack),
              const SizedBox(height: 24),
              Center(
                child: OneirAssetPlaceholder(description: 'Vanya illustration: listening, curious', width: 130, height: 110),
              ),
              const SizedBox(height: 16),
              Text('What brings you here today?',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, height: 1.25, color: OneirColors.text)),
              const SizedBox(height: 8),
              Text('This helps Vanya know what to focus on with you.',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
              const SizedBox(height: 24),
              for (final reason in _reasons) ...[
                OneirSelectionRow(
                  leading: Icon(reason.icon, size: 20, color: _selected == reason.label ? OneirColors.text : OneirColors.textMuted),
                  label: reason.label,
                  selected: _selected == reason.label,
                  onTap: () => setState(() => _selected = reason.label),
                ),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              OneirPrimaryButton(label: "That's it, exactly", onPressed: _selected == null ? null : _handleContinue),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/oneir_theme.dart';
import '../../widgets/shared.dart';
import '../providers/intervention_controller.dart';
import '../providers/intervention_state.dart';
import '../models/intervention_decision.dart';
import '../ai/ai_intervention_provider.dart';
import '../voice/voice_queue_controller.dart';

/// The full-screen Vanya overlay shown when a protected app opens. Reuses
/// the existing design system (OneirColors/OneirText/shared buttons) --
/// this is new *behavior*, not a new visual language.
class InterventionConversationScreen extends ConsumerStatefulWidget {
  final String appLabel;
  final String packageName;
  final bool isReLockFollowUp;
  final VoidCallback onDismiss;
  final VoidCallback onLaunchApp;

  const InterventionConversationScreen({
    super.key,
    required this.appLabel,
    required this.packageName,
    required this.onDismiss,
    required this.onLaunchApp,
    this.isReLockFollowUp = false,
  });

  @override
  ConsumerState<InterventionConversationScreen> createState() => _InterventionConversationScreenState();
}

class _InterventionConversationScreenState extends ConsumerState<InterventionConversationScreen> {
  final _controller = TextEditingController();
  bool _hasInterruptedForThisTurn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interventionControllerProvider.notifier).start(
            appLabel: widget.appLabel,
            packageName: widget.packageName,
            isReLockFollowUp: widget.isReLockFollowUp,
          );
      if (!widget.isReLockFollowUp) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) ref.read(interventionControllerProvider.notifier).readyForInput();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Belt-and-braces: if this screen is torn down for any reason (e.g.
    // the native side dismisses the Activity abruptly), Vanya shouldn't
    // keep talking into a closed overlay.
    ref.read(voiceQueueControllerProvider.notifier).interrupt();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    _hasInterruptedForThisTurn = false;
    ref.read(interventionControllerProvider.notifier).submitUserMessage(text);
  }

  /// The moment the user starts typing an answer, Vanya shouldn't keep
  /// talking over them -- interrupt on the first keystroke of each turn
  /// rather than on every keystroke.
  void _onTextChanged(String value) {
    if (!_hasInterruptedForThisTurn && value.isNotEmpty) {
      _hasInterruptedForThisTurn = true;
      ref.read(voiceQueueControllerProvider.notifier).interrupt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interventionControllerProvider);

    ref.listen(interventionControllerProvider, (previous, next) {
      if (next?.stage == InterventionStage.closed) {
        if (next?.lastDecision?.decision == InterventionDecisionType.allow) {
          widget.onLaunchApp();
        } else {
          widget.onDismiss();
        }
      }
      if (previous?.stage != next?.stage) {
        _hasInterruptedForThisTurn = false;
      }
    });

    if (state == null) {
      return const Scaffold(backgroundColor: Colors.black26, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 340,
            constraints: const BoxConstraints(maxHeight: 640),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(color: OneirColors.background, borderRadius: BorderRadius.circular(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _VoiceControlsRow(),
                const OneirAssetPlaceholder(description: 'Vanya illustration/animation: intervention companion', width: 110, height: 110),
                const SizedBox(height: 12),
                Flexible(child: _buildStageContent(state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent(InterventionState state) {
    switch (state.stage) {
      case InterventionStage.detecting:
        return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));

      case InterventionStage.speaking:
        return _headline('Hi. What are you hoping to do?');

      case InterventionStage.awaitingInput:
      case InterventionStage.clarifying:
        return _conversationWithInput(state);

      case InterventionStage.thinking:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _conversationHistory(state),
          const SizedBox(height: 16),
          const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ]);

      case InterventionStage.decided:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _headline(state.lastDecision?.reply ?? ''),
          const SizedBox(height: 20),
          OneirPrimaryButton(label: 'Okay', onPressed: () => ref.read(interventionControllerProvider.notifier).close()),
        ]);

      case InterventionStage.sessionActive:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text("You're set for ${widget.appLabel}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 18, color: OneirColors.text)),
          const SizedBox(height: 8),
          const Text("I'll check back in when your time is up.",
              textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
        ]);

      case InterventionStage.reLockPrompt:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _headline('Have you finished?'),
          const SizedBox(height: 20),
          OneirPrimaryButton(label: "Yes, I'm done", onPressed: () => ref.read(interventionControllerProvider.notifier).confirmSessionFinished()),
          const SizedBox(height: 10),
          OneirSecondaryButton(
            label: 'Not quite, one more moment',
            onPressed: () => _showMoreTimeSheet(state),
          ),
        ]);

      case InterventionStage.closed:
        return const SizedBox.shrink();
    }
  }

  Widget _headline(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 18, height: 1.4, color: OneirColors.text),
    );
  }

  Widget _conversationHistory(InterventionState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final turn in state.history) _ChatBubble(turn: turn),
      ],
    );
  }

  Widget _conversationWithInput(InterventionState state) {
    final question = state.stage == InterventionStage.clarifying
        ? (state.lastDecision?.clarifyingQuestion ?? state.lastDecision?.reply ?? "What's going on?")
        : "What's bringing you to ${widget.appLabel}?";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.history.isNotEmpty) ...[
          _conversationHistory(state),
          const SizedBox(height: 8),
        ],
        _headline(question),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 2,
          onChanged: _onTextChanged,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.text),
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            filled: true,
            fillColor: OneirColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OneirPrimaryButton(label: 'Send', onPressed: _submit),
      ],
    );
  }

  void _showMoreTimeSheet(InterventionState state) {
    final extraController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: OneirColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What do you still need to finish?',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 16, color: OneirColors.text)),
            const SizedBox(height: 12),
            TextField(
              controller: extraController,
              autofocus: true,
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: OneirColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            OneirPrimaryButton(
              label: 'Send',
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(interventionControllerProvider.notifier).requestMoreTime(extraController.text);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Small header row: replay the last thing Vanya said, and adjust how
/// fast she speaks. Kept tiny and unobtrusive -- this is a utility control,
/// not a feature to draw attention to.
class _VoiceControlsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceQueueControllerProvider);
    final voiceController = ref.read(voiceQueueControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: voiceController.hasSomethingToReplay ? voiceController.replay : null,
          icon: Icon(Icons.replay, size: 18, color: voiceController.hasSomethingToReplay ? OneirColors.textMuted : OneirColors.textFaint),
          tooltip: 'Replay',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () => _showSpeedSheet(context, ref, voiceState.rate),
          icon: const Icon(Icons.speed, size: 18, color: OneirColors.textMuted),
          tooltip: 'Speaking speed',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _showSpeedSheet(BuildContext context, WidgetRef ref, double currentRate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OneirColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          var localRate = currentRate;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Speaking speed', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 16, color: OneirColors.text)),
                Slider(
                  value: localRate,
                  min: 0.2,
                  max: 0.9,
                  activeColor: OneirColors.periwinkle,
                  onChanged: (v) => setSheetState(() => localRate = v),
                  onChangeEnd: (v) => ref.read(voiceQueueControllerProvider.notifier).setRate(v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final InterventionTurn turn;
  const _ChatBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: isUser ? OneirColors.periwinkle : OneirColors.cardNeutral,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          turn.text,
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: isUser ? Colors.white : OneirColors.text),
        ),
      ),
    );
  }
}

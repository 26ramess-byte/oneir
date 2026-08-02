import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../backend/co_keeper_backend.dart';
import '../backend/oneir_identity.dart';

class CoKeeperIntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;
  const CoKeeperIntroScreen({super.key, required this.onNext, required this.onSkip, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 6 / 14, onBack: onBack),
              const SizedBox(height: 8),
              Expanded(
                flex: 4,
                child: Center(
                  child: const OneirAssetPlaceholder(description: 'Vanya illustration: holding a small brass key', width: 200, height: 220),
                ),
              ),
              const SizedBox(height: 20),
              Text("Who's your team?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 24, letterSpacing: -0.4, height: 1.3, color: OneirColors.text)),
              const SizedBox(height: 16),
              Text(
                'When you need extra support, someone you trust can hold a key for you.\n\n'
                'They never see your activity. They only help unlock protected apps when you choose.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.6, color: OneirColors.textMuted),
              ),
              const Spacer(),
              OneirPrimaryButton(label: 'Add a Co-Keeper', onPressed: onNext),
              const SizedBox(height: 10),
              OneirSecondaryButton(label: 'Maybe Later', onPressed: onSkip),
            ],
          ),
        ),
      ),
    );
  }
}

const _relations = ['Mum', 'Dad', 'Friend', 'Partner', 'Sibling', 'Mentor'];

class CoKeeperInviteScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const CoKeeperInviteScreen({super.key, required this.onNext, this.onBack});

  @override
  State<CoKeeperInviteScreen> createState() => _CoKeeperInviteScreenState();
}

class _CoKeeperInviteScreenState extends State<CoKeeperInviteScreen> {
  int _step = 1;
  String? _relation;
  String? _contactMode; // "contacts" | "manual"
  final _contactController = TextEditingController();
  String _deviceId = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    OneirIdentity.getOrCreateDeviceId().then((id) {
      if (mounted) setState(() => _deviceId = id);
    });
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    setState(() => _sending = true);
    try {
      await CoKeeperBackend.createPendingPairing(coKeeperName: _relation ?? 'your Co-Keeper');
    } catch (e) {
      // Firebase isn't configured yet in this environment -- still advance
      // to the celebration screen for preview purposes rather than getting
      // stuck here, but the pairing itself didn't actually save anywhere.
      debugPrint('Could not save Co-Keeper pairing (Firebase not configured?): $e');
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _step = 4;
    });
  }

  void _backWithinFlow() {
    if (_step > 1) {
      setState(() => _step -= 1);
    } else {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    late final Widget content;
    late final Widget button;
    switch (_step) {
      case 1:
        content = _stepRelationContent();
        button = OneirPrimaryButton(label: 'Continue', onPressed: _relation == null ? null : () => setState(() => _step = 2));
        break;
      case 2:
        final canContinue = _contactMode == 'contacts' || (_contactMode == 'manual' && _contactController.text.isNotEmpty);
        content = _stepContactContent();
        button = OneirPrimaryButton(label: 'Continue', onPressed: canContinue ? () => setState(() => _step = 3) : null);
        break;
      case 3:
        content = _stepInviteContent();
        button = OneirPrimaryButton(label: _sending ? 'Sending...' : 'Send Invite', onPressed: _sending ? null : _sendInvite);
        break;
      default:
        content = _stepCelebrationContent();
        button = OneirPrimaryButton(label: 'Continue', onPressed: widget.onNext);
    }

    // Sub-progress within step 7/14 (Invite Co-Keeper), moving through its
    // internal steps rather than jumping straight to 8/14.
    final subProgress = (6 + (_step / 4)) / 14;

    return OneirScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
        child: Column(children: [
          OneirProgressHeader(progress: subProgress, onBack: _backWithinFlow),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: content)),
          const SizedBox(height: 16),
          button,
        ]),
      ),
    );
  }

  Widget _stepRelationContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Who helps you stay on track?',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 22, height: 1.3, color: OneirColors.text)),
      const SizedBox(height: 24),
      for (final r in _relations) ...[
        OneirSelectionRow(label: r, selected: _relation == r, onTap: () => setState(() => _relation = r)),
        const SizedBox(height: 10),
      ],
    ]);
  }

  Widget _stepContactContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How should we reach them?',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 22, height: 1.3, color: OneirColors.text)),
      const SizedBox(height: 24),
      OneirSelectionRow(label: 'Choose from contacts', selected: _contactMode == 'contacts', onTap: () => setState(() => _contactMode = 'contacts')),
      const SizedBox(height: 10),
      OneirSelectionRow(label: 'Type manually', selected: _contactMode == 'manual', onTap: () => setState(() => _contactMode = 'manual')),
      if (_contactMode == 'manual') ...[
        const SizedBox(height: 10),
        TextField(
          controller: _contactController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "${_relation ?? 'Their'}'s phone or email",
            filled: true,
            fillColor: OneirColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    ]);
  }

  String get _inviteMessage {
    // NOTE: oneir.app is a placeholder domain -- this needs real app-hosting
    // (e.g. a Firebase Dynamic Link or a simple web page that deep-links
    // into the app) before this link actually opens anything for the person
    // who receives it.
    final link = 'https://oneir.app/pair?from=$_deviceId';
    return "Hi! I've started using Oneir to reduce mindless scrolling. Would you be my Co-Keeper? "
        "This simply means you can help me unlock protected apps when I'm struggling. "
        "You won't see what I do or any personal information.\n\n$link";
  }

  Widget _stepInviteContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Center(child: OneirAssetPlaceholder(description: 'Vanya illustration: holding an envelope', width: 140, height: 100)),
      const SizedBox(height: 16),
      Text('Invite $_relation', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 22, height: 1.3, color: OneirColors.text)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFFFAFAFA), border: Border.all(color: const Color(0xFFE5E5E5)), borderRadius: BorderRadius.circular(18)),
        child: Text(_inviteMessage, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, height: 1.6, color: OneirColors.textMuted)),
      ),
    ]);
  }

  Widget _stepCelebrationContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        const OneirAssetPlaceholder(description: 'Vanya illustration: celebrating with the key safe', width: 160, height: 140),
        const SizedBox(height: 20),
        Text('The key has found a safe home.', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 20, color: OneirColors.text)),
        const SizedBox(height: 10),
        Text('$_relation will be notified once they accept.', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.textFaint)),
      ]),
    );
  }
}

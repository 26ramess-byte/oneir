import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';
import 'settings_screen.dart';

const kWidgetTasks = ['Say hi to Vanya', 'Finish Biology', 'Read 10 pages'];

class WidgetsScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WidgetsScreen({super.key, required this.onNext, this.onBack});

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  final List<bool> _checked = [false, false, false];

  int get _doneCount => _checked.where((c) => c).length;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await OneirProtection.loadTaskState();
    if (!mounted || saved == null) return;
    setState(() {
      for (var i = 0; i < _checked.length && i < saved.length; i++) {
        _checked[i] = saved[i];
      }
    });
  }

  Future<void> _persist() async {
    await OneirProtection.saveTaskState(_checked);
    var firstUnfinished = '';
    for (var i = 0; i < kWidgetTasks.length; i++) {
      if (!_checked[i]) {
        firstUnfinished = kWidgetTasks[i];
        break;
      }
    }
    await OneirProtection.saveCurrentIntention(firstUnfinished);
  }

  Future<void> _handleContinue() async {
    await OneirProtection.setOnboardingComplete();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _doneCount / kWidgetTasks.length;

    return OneirScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OneirProgressHeader(progress: 12 / 14, onBack: widget.onBack),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Widget card -- content gets right padding reserved so the corner
          // image (placed via the trailing Stack entry, aligned within the
          // card's own bounds) never sits on top of the task text.
          Container(
            decoration: BoxDecoration(
              color: OneirColors.cardNeutral,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 110, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text("Today's Adventure", style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 16, color: OneirColors.text)),
                  const SizedBox(height: 14),
                  for (var i = 0; i < kWidgetTasks.length; i++)
                    GestureDetector(
                      onTap: () {
                        setState(() => _checked[i] = !_checked[i]);
                        _persist();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: _checked[i] ? OneirColors.text : Colors.transparent,
                              border: _checked[i] ? null : Border.all(color: OneirColors.border, width: 1.5),
                            ),
                            child: _checked[i] ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            kWidgetTasks[i],
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans', fontSize: 14,
                              color: _checked[i] ? const Color(0xFFB0B0B0) : OneirColors.text,
                              decoration: _checked[i] ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 6,
                      backgroundColor: const Color(0xFFE5E5E5),
                      valueColor: const AlwaysStoppedAnimation(OneirColors.text),
                    ),
                  ),
                ]),
              ),
              Positioned(
                right: 4, bottom: 4,
                child: const OneirAssetPlaceholder(description: 'Vanya illustration: drinking tea', width: 100, height: 100),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          Center(
            child: AnimatedScale(
              scale: _doneCount == kWidgetTasks.length ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: const OneirAssetPlaceholder(description: 'Vanya illustration: drinking tea', width: 220, height: 220),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Your widgets remind you what matters before you even think about scrolling.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20.6, height: 1.5, color: OneirColors.textMuted),
            ),
          ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          OneirPrimaryButton(label: 'This feels good', onPressed: _handleContinue),
        ]),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const SectionCard({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 28, child: Align(alignment: Alignment.bottomLeft, child: Icon(icon, size: 26, color: OneirColors.textMuted))),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w500, color: OneirColors.text)),
      ]),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<bool> _checked = List.filled(kWidgetTasks.length, false);
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await OneirProtection.loadTaskState();
    if (!mounted || saved == null) return;
    setState(() {
      for (var i = 0; i < _checked.length && i < saved.length; i++) {
        _checked[i] = saved[i];
      }
    });
  }

  Future<void> _toggle(int i) async {
    final wasUnchecked = !_checked[i];
    setState(() => _checked[i] = !_checked[i]);
    await OneirProtection.saveTaskState(_checked);
    // A real "win" moment: Vanya visibly celebrates the very first task you
    // complete on the actual Home screen, not just during onboarding demos --
    // this is the first genuine success the app can show back to you.
    if (wasUnchecked && _checked[i]) {
      setState(() => _celebrating = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _celebrating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning, ${widget.name.isEmpty ? "Alex" : widget.name}',
                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.4, color: OneirColors.text)),
                    const SizedBox(height: 2),
                    const Text('Tue, 22 Jul', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
                  ],
                ),
              ),
              Material(
                color: OneirColors.cardNeutral,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.settings_outlined, size: 22, color: OneirColors.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: OneirColors.cardNeutral,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 92, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text("Today's Adventure", style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < kWidgetTasks.length; i++)
                    GestureDetector(
                      onTap: () => _toggle(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: _checked[i] ? OneirColors.text : Colors.transparent,
                              border: _checked[i] ? null : Border.all(color: OneirColors.border, width: 1.5),
                            ),
                            child: _checked[i] ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            kWidgetTasks[i],
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans', fontSize: 13,
                              color: _checked[i] ? const Color(0xFFB0B0B0) : OneirColors.text,
                              decoration: _checked[i] ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
              Positioned(
                right: 4, bottom: 4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _celebrating
                      ? const OneirAssetPlaceholder(key: ValueKey('cheer'), description: 'Vanya illustration: cheering', width: 80, height: 80)
                      : const OneirAssetPlaceholder(key: ValueKey('tea'), description: 'Vanya illustration: drinking tea', width: 80, height: 80),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: const [
              SectionCard(label: 'Tasks', icon: Icons.checklist_rounded),
              SectionCard(label: 'Protected Apps', icon: Icons.shield_outlined),
              SectionCard(label: 'Focus Time', icon: Icons.local_cafe_outlined),
              SectionCard(label: 'Statistics', icon: Icons.insights_outlined),
            ],
          ),
          const SizedBox(height: 22),
          Text('Your streaks', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: OneirStreakWidgetCard(title: 'Focus Streak', currentDay: 3, totalDays: 30)),
              SizedBox(width: 12),
              Expanded(child: OneirStreakWidgetCard(title: 'Study Streak', currentDay: 0, totalDays: 14, locked: true)),
            ],
          ),
        ]),
        ),
      ),
    );
  }
}

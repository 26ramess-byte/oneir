import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onNext;
  const SplashScreen({super.key, required this.onNext});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), widget.onNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: GestureDetector(
        onTap: widget.onNext,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned(
              left: 51.5,
              top: 176,
              width: 248.7,
              height: 76.7,
              child: Text(
                'Vanya',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w500,
                  fontSize: 50,
                  height: 1,
                  color: OneirColors.splashWordmark,
                ),
              ),
            ),
            Positioned(
              left: 63.85,
              top: 283.6,
              width: 224,
              height: 269.7,
              child: OneirAssetPlaceholder(description: 'Vanya illustration: sitting, splash logo', width: 224, height: 269.7),
            ),
          ],
        ),
      ),
    );
  }
}

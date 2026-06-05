import 'dart:async';
import 'package:flutter/material.dart';

mixin FlashMessageMixin on ChangeNotifier {
  bool isFlashVisible = false;
  String flashMsg = '';
  Color flashColor = Colors.blue;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void showFlash(String msg, Color color) {
    _flashTimer?.cancel();
    flashMsg = msg;
    flashColor = color;
    isFlashVisible = true;
    notifyListeners();

    _flashTimer = Timer(const Duration(milliseconds: 1500), () {
      isFlashVisible = false;
      notifyListeners();
    });
  }
}

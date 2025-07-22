import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/routes.dart';

class WelcomeViewModel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void navigateToHome(BuildContext context) {
    _isLoading = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
      notifyListeners();
      context.go(AppRoutes.home);
    });
  }
}